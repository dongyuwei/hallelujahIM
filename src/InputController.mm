#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

#import "InputApplicationDelegate.h"
#import "InputController.h"
#import "NSScreen+PointConversion.h"
#import "RimeEngine.h"
#import "RimeKeymap.h"

extern IMKCandidates *sharedCandidates;
extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern RimeEngine *rimeEngine;

typedef NSInteger KeyCode;
static const KeyCode KEY_RETURN = 36, KEY_SPACE = 49, KEY_DELETE = 51, KEY_ESC = 53, KEY_ARROW_DOWN = 125, KEY_ARROW_UP = 126,
                     KEY_ARROW_LEFT = 123, KEY_ARROW_RIGHT = 124, KEY_RIGHT_SHIFT = 60, KEY_RIGHT_COMMAND = 54;

// Grid panels lay candidates out 5 per row (kIMKScrollingGridCandidatePanel),
// but the panel recomputes its column count from the available width on its
// own, so coordinates are never derived here — the panel's own move*: methods
// do the geometry and the resulting highlight is read back afterwards.

// IMKCandidates implements expand/isExpanded/setSortingModes at runtime but
// does not declare them in its public SDK header (same position as
// moveLeft:/moveRight:, which are NSResponder methods that IMKCandidates
// overrides). Verifying respondsToSelector: before calling keeps the fallback
// safe on older systems. Without a sorting-modes list (even an empty one) the
// grid panel's expand asserts on nil segment labels, so set @[] first.
@interface IMKCandidates (GridNavigationSPI)
- (BOOL)isExpanded;
- (void)expand;
- (void)setSortingModes:(NSArray *)modes;
@end

// English and Chinese (half-width and full-width) punctuation each count as
// their language for mixed mode's dynamic candidate ordering.
static BOOL ContainsChineseCharacter(NSString *text) {
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar ch = [text characterAtIndex:i];
        BOOL han = (ch >= 0x3400 && ch <= 0x4DBF) || (ch >= 0x4E00 && ch <= 0x9FFF) || (ch >= 0xF900 && ch <= 0xFAFF);
        // CJK Symbols and Punctuation (。、《》【】…) and Fullwidth Forms (，：？！…)
        BOOL chinesePunctuation = (ch >= 0x3000 && ch <= 0x303F) || (ch >= 0xFF00 && ch <= 0xFFEF);
        if (han || chinesePunctuation) {
            return YES;
        }
    }
    return NO;
}

@interface InputController ()

@end

@implementation InputController

- (NSUInteger)recognizedEvents:(id)sender {
    return NSEventMaskKeyDown | NSEventMaskFlagsChanged;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    NSUInteger modifiers = event.modifierFlags;
    bool handled = NO;
    switch (event.type) {
    case NSEventTypeFlagsChanged:
        // NSLog(@"hallelujah event modifierFlags %lu, event keyCode: %@", (unsigned long)[event modifierFlags], [event keyCode]);

        if (_lastEventTypes[1] == NSEventTypeFlagsChanged && _lastModifiers[1] == modifiers) {
            return YES;
        }

        // Right Command key: toggle pinyin mode (disabled in mixed mode)
        if (modifiers == 0 && _lastEventTypes[1] == NSEventTypeFlagsChanged && event.keyCode == KEY_RIGHT_COMMAND && ![self mixedInput]) {
            _pinyinMode = !_pinyinMode;
            if (_pinyinMode) {
                // commit what was typed in english mode so far before entering pinyin mode
                NSString *bufferedText = [self originalBuffer];
                if (bufferedText && bufferedText.length > 0) {
                    [self cancelComposition];
                    [self commitCompositionWithoutSpace:sender];
                }
                [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
            } else {
                // flush rime's unconverted input as plain text before going back to english mode
                NSString *rawInput = [rimeEngine rawInput:(RimeSessionId)_rimeSession];
                [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
                if (rawInput.length > 0) {
                    [sender insertText:rawInput replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
                }
            }
            [self reset];
        }

        if (modifiers == 0 && _lastEventTypes[1] == NSEventTypeFlagsChanged && _lastModifiers[1] == NSEventModifierFlagShift &&
            event.keyCode == KEY_RIGHT_SHIFT && !(_lastModifiers[0] & NSEventModifierFlagShift)) {

            _defaultEnglishMode = !_defaultEnglishMode;
            if (_defaultEnglishMode) {
                NSString *bufferedText = [self originalBuffer];
                if (bufferedText && bufferedText.length > 0) {
                    [self cancelComposition];
                    [self commitComposition:sender];
                }
            }
        }
        break;
    case NSEventTypeKeyDown:
        if (_defaultEnglishMode) {
            break;
        }

        // ignore Command+X hotkeys.
        if (modifiers & NSEventModifierFlagCommand)
            break;

        if (_pinyinMode || [self mixedInput]) {
            handled = [self onRimeKeyEvent:event client:sender];
            break;
        }

        if (modifiers & NSEventModifierFlagOption) {
            return false;
        }

        if (modifiers & NSEventModifierFlagControl) {
            return false;
        }

        handled = [self onKeyEvent:event client:sender];
        break;
    default:
        break;
    }

    _lastModifiers[0] = _lastModifiers[1];
    _lastEventTypes[0] = _lastEventTypes[1];
    _lastModifiers[1] = modifiers;
    _lastEventTypes[1] = event.type;
    return handled;
}

// Mixed Chinese/English input: both engines run side by side and each page
// shows 5 English candidates (digits 1-5) followed by 4 Chinese candidates
// (digits 6-9). Rime still drives the composition; the English query runs
// against Rime's raw input.
- (BOOL)mixedInput {
    return [preference boolForKey:@"mixedInput"];
}

- (BOOL)onRimeKeyEvent:(NSEvent *)event client:(id)sender {
    _currentClient = sender;

    if (_rimeSession == 0 || ![rimeEngine sessionAlive:(RimeSessionId)_rimeSession]) {
        _rimeSession = [rimeEngine createSession];
    }
    if (_rimeSession == 0) {
        return NO;
    }

    // Candidate selection and up/down navigation are owned by the input
    // method, not Rime: digits pick a row, space commits the highlighted row,
    // arrows move the highlight. Rime only builds the composition; the
    // Chinese rows commit through selectCandidateOnCurrentPage.
    NSString *rawInput = [rimeEngine rawInput:(RimeSessionId)_rimeSession];

    // Mixed mode: punctuation follows the last committed language. After
    // English (or before anything was committed), punctuation is passed
    // through as-is — any pending input is flushed raw first. After Chinese,
    // Rime converts it to full-width punctuation.
    if ([self mixedInput] && !_lastCommittedWasChinese && event.characters.length == 1) {
        unichar ch = [event.characters characterAtIndex:0];
        if (([[NSCharacterSet punctuationCharacterSet] characterIsMember:ch] ||
             [[NSCharacterSet symbolCharacterSet] characterIsMember:ch])) {
            if (rawInput.length > 0) {
                [sender insertText:rawInput replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
                [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
                [self rimeUpdate:sender];
            }
            return NO; // let the app type the punctuation itself
        }
    }

    if (rawInput.length > 0) {
        NSString *chars = event.characters;
        if (chars.length == 1) {
            unichar ch = [chars characterAtIndex:0];
            if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch] && [self onCandidateDigitKey:chars sender:sender]) {
                return YES;
            }
            if (ch == ' ' && [self commitHighlightedCandidateWithSpace:YES sender:sender]) {
                return YES;
            }
        }
        if (event.keyCode == KEY_RETURN && [self commitHighlightedCandidateWithSpace:NO sender:sender]) {
            return YES;
        }
        if ((event.keyCode == KEY_ARROW_DOWN || event.keyCode == KEY_ARROW_UP || event.keyCode == KEY_ARROW_LEFT ||
             event.keyCode == KEY_ARROW_RIGHT) &&
            [self navigateGridPanelWithKeyCode:event.keyCode sender:sender]) {
            return YES;
        }
        if (event.keyCode == KEY_ARROW_DOWN && [self moveCandidateSelection:YES sender:sender]) {
            return YES;
        }
        if (event.keyCode == KEY_ARROW_UP && [self moveCandidateSelection:NO sender:sender]) {
            return YES;
        }
    }

    // Pick the character to translate: with only shift/caps held, punctuation
    // keys must use the shifted character (shift+; -> ':'), because librime's
    // punctuator matches on the raw keysym and ignores the shift mask. With
    // other modifiers, non-ASCII characters (e.g. option combos) keep their
    // composed character. Mirrors Squirrel's SquirrelInputController logic.
    NSString *keyChars = event.charactersIgnoringModifiers;
    NSEventModifierFlags relevantModifiers =
        event.modifierFlags & (NSEventModifierFlagShift | NSEventModifierFlagCapsLock | NSEventModifierFlagControl |
                               NSEventModifierFlagOption | NSEventModifierFlagCommand);
    BOOL capitalModifiersOnly = (relevantModifiers & ~(NSEventModifierFlagShift | NSEventModifierFlagCapsLock)) == 0;
    if (keyChars.length > 0) {
        unichar first = [keyChars characterAtIndex:0];
        BOOL isLetter = [[NSCharacterSet letterCharacterSet] characterIsMember:first];
        if ((capitalModifiersOnly && !isLetter) || (!capitalModifiersOnly && first > 0x7f)) {
            keyChars = event.characters;
        }
    }

    int keycode = [RimeKeymap rimeKeycodeForKeyCode:event.keyCode character:keyChars modifierFlags:event.modifierFlags];
    if (keycode == RimeXK_VoidSymbol) {
        return NO;
    }
    int mask = [RimeKeymap rimeMaskForModifiers:event.modifierFlags];
    BOOL handled = [rimeEngine processKey:(RimeSessionId)_rimeSession keycode:keycode mask:mask];
    [self rimeUpdate:sender];
    return handled;
}

// Digits pick a row of the candidate panel (row 1-9).
- (BOOL)onCandidateDigitKey:(NSString *)chars sender:(id)sender {
    int digit = chars.intValue;
    if (digit < 1 || digit > 9 || digit > (int)_candidates.count) {
        return NO; // not a selectable row; let Rime/app handle the digit
    }
    [self commitSelectedRow:digit - 1 withSpace:YES sender:sender];
    return YES;
}

// Space commits the highlighted row (with the trailing-space preference);
// Enter commits it without a trailing space. With no candidates left, hand
// the key back to Rime (e.g. to commit the raw input).
- (BOOL)commitHighlightedCandidateWithSpace:(BOOL)withSpace sender:(id)sender {
    if (_candidates.count == 0) {
        return NO;
    }
    NSInteger row = _panelHighlight;
    if (row < 0 || row >= (NSInteger)_candidates.count) {
        row = 0;
    }
    [self commitSelectedRow:row withSpace:withSpace sender:sender];
    return YES;
}

- (BOOL)moveCandidateSelection:(BOOL)down sender:(id)sender {
    if (_candidates.count == 0) {
        return NO;
    }
    NSInteger row = down ? MIN(_panelHighlight + 1, (NSInteger)_candidates.count - 1) : MAX(_panelHighlight - 1, 0);
    if (row == _panelHighlight) {
        return YES;
    }
    if (down) {
        [sharedCandidates moveDown:self];
    } else {
        [sharedCandidates moveUp:self];
    }
    _panelHighlight = row;
    return YES;
}
// Arrow-key navigation for the grid candidate panel. The first down-arrow
// press expands the collapsed panel so every row is visible; afterwards
// left/right/up/down are passed to the panel's own move*: methods (which
// handle the column geometry). In grid mode arrow keys are always consumed so
// the event never falls through to the single-column path. Returns NO only
// when the grid panel preference is off.
- (BOOL)navigateGridPanelWithKeyCode:(NSInteger)keyCode sender:(id)sender {
    if (![preference boolForKey:@"useGridCandidatePanel"]) {
        return NO;
    }
    if (_candidates.count == 0) {
        return NO;
    }
    if (keyCode == KEY_ARROW_DOWN && [sharedCandidates respondsToSelector:@selector(isExpanded)] && ![sharedCandidates isExpanded]) {
        if ([sharedCandidates respondsToSelector:@selector(setSortingModes:)]) {
            [sharedCandidates setSortingModes:@[]]; // SPI: expand asserts on nil sorting labels otherwise
        }
        [sharedCandidates expand]; // first down-press: reveal the full grid
        return YES;
    }
    switch (keyCode) {
    case KEY_ARROW_LEFT:
        [sharedCandidates moveLeft:self];
        break;
    case KEY_ARROW_RIGHT:
        [sharedCandidates moveRight:self];
        break;
    case KEY_ARROW_UP:
        [sharedCandidates moveUp:self];
        break;
    case KEY_ARROW_DOWN:
        [sharedCandidates moveDown:self];
        break;
    default:
        return NO;
    }
    [self syncGridSelectionHighlight];
    return YES;
}

// The panel never calls candidateSelectionChanged: for programmatic move*:
// moves, so read the panel's own highlight back after moving and mirror it
// into the composition state (in English mode space/enter commit
// _composedBuffer).
- (void)syncGridSelectionHighlight {
    [self applyGridSelectionString:[sharedCandidates selectedCandidateString].string];
}

// Mirrors the grid panel's highlighted candidate into _panelHighlight and the
// composition state. Pinyin/mixed modes commit straight from _panelHighlight;
// English mode commits _composedBuffer, which is kept in sync here.
- (void)applyGridSelectionString:(NSString *)candidateString {
    if (candidateString.length == 0) {
        return;
    }
    NSInteger idx = [_candidates indexOfObject:candidateString];
    if (idx != NSNotFound) {
        _panelHighlight = idx;
    }
    if (_panelHighlight < 0 || _panelHighlight >= (NSInteger)_candidates.count) {
        return;
    }
    if (_pinyinMode || [self mixedInput]) {
        return;
    }
    NSString *word = _candidates[_panelHighlight];
    [self setComposedBuffer:word];
    [self showPreeditString:word];
    _insertionIndex = word.length;
}

// Commits the candidate shown on the given panel row. English rows (mixed
// mode) go through the English commit path; Chinese rows map back to their
// Rime page index and commit through Rime.
- (void)commitSelectedRow:(NSInteger)row withSpace:(BOOL)withSpace sender:(id)sender {
    if (row < 0 || row >= (NSInteger)_candidates.count) {
        return;
    }
    NSString *word = _candidates[row];
    if ([self mixedInput] && [_mixedRowIsEnglish[row] boolValue]) {
        [self commitEnglishCandidateWord:word withSpace:withSpace sender:sender];
        return;
    }
    NSInteger rimeIndex = row;
    if ([self mixedInput]) {
        rimeIndex = [_mixedRowRimeIndexes[row] integerValue];
    }
    [rimeEngine selectCandidateOnCurrentPage:(RimeSessionId)_rimeSession index:rimeIndex];
    [self rimeUpdate:sender];
}

- (void)commitEnglishCandidateWord:(NSString *)word withSpace:(BOOL)withSpace sender:(id)sender {
    [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
    [self setComposedBuffer:word];
    [self setOriginalBuffer:word];
    if (withSpace) {
        [self commitEnglishComposition:sender];
    } else {
        [self commitCompositionWithoutSpace:sender];
    }
    _lastCommittedWasChinese = NO;
    [self rimeUpdate:sender];
}

// Single refresh point after every processed key: deliver pending commit,
// mirror Rime's preedit into inline marked text, and feed the candidate panel
// with the current page of candidates.
- (void)rimeUpdate:(id)sender {
    NSString *commitText = [rimeEngine commitText:(RimeSessionId)_rimeSession];
    if (commitText.length > 0) {
        [sender insertText:commitText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        // remember the language for mixed mode's dynamic candidate ordering
        _lastCommittedWasChinese = ContainsChineseCharacter(commitText);
    }

    NSArray<RimeCandidateItem *> *rimeCandidates = [rimeEngine candidates:(RimeSessionId)_rimeSession];
    _candidates = [NSMutableArray array];
    _rimePageCandidates = [NSMutableArray array];
    for (RimeCandidateItem *candidate in rimeCandidates) {
        [_candidates addObject:candidate.text];
        [_rimePageCandidates addObject:candidate.text];
    }

    // in mixed mode the English query follows Rime's raw input
    if ([self mixedInput]) {
        [self setOriginalBuffer:[rimeEngine rawInput:(RimeSessionId)_rimeSession]];
    }

    NSInteger selStart = 0, selLength = 0, caretPos = 0;
    NSString *preedit = [rimeEngine preedit:(RimeSessionId)_rimeSession selStart:&selStart selLength:&selLength caretPos:&caretPos];
    if (preedit.length == 0) {
        [sharedCandidates hide];
        _panelHighlight = 0;
        return;
    }

    [sharedCandidates clearSelection];
    [sharedCandidates updateCandidates];
    [sharedCandidates show:kIMKLocateCandidatesBelowHint];
    // selection state is owned by the input method; a fresh page starts at row 0
    _panelHighlight = 0;

    NSDictionary *rawAttrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, preedit.length)];
    NSDictionary *convertedAttrs = [self markForStyle:kTSMHiliteConvertedText atRange:NSMakeRange(0, preedit.length)];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:preedit attributes:rawAttrs];
    if (selLength > 0) {
        [attrString setAttributes:convertedAttrs range:NSMakeRange(selStart, selLength)];
    }
    [_currentClient setMarkedText:attrString selectionRange:NSMakeRange(caretPos, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (BOOL)onKeyEvent:(NSEvent *)event client:(id)sender {
    _currentClient = sender;
    NSInteger keyCode = event.keyCode;
    NSString *characters = event.characters;

    NSString *bufferedText = [self originalBuffer];
    bool hasBufferedText = bufferedText && bufferedText.length > 0;

    if (keyCode == KEY_DELETE) {
        if (hasBufferedText) {
            return [self deleteBackward:sender];
        }

        return NO;
    }

    if (keyCode == KEY_SPACE) {
        if (hasBufferedText) {
            [self commitComposition:sender];
            return YES;
        }
        return NO;
    }

    if (keyCode == KEY_RETURN) {
        if (hasBufferedText) {
            [self commitCompositionWithoutSpace:sender];
            return YES;
        }
        return NO;
    }

    if (keyCode == KEY_ESC) {
        [self cancelComposition];
        [sender insertText:@""];
        [self reset];
        return YES;
    }

    char ch = [characters characterAtIndex:0];
    if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
        [self originalBufferAppend:characters client:sender];

        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
    }

    if ([self isMojaveAndLaterSystem]) {
        BOOL isCandidatesVisible = [sharedCandidates isVisible];
        if (isCandidatesVisible) {
            if (keyCode == KEY_ARROW_DOWN || keyCode == KEY_ARROW_UP || keyCode == KEY_ARROW_LEFT || keyCode == KEY_ARROW_RIGHT) {
                if ([self navigateGridPanelWithKeyCode:keyCode sender:sender]) {
                    return YES;
                }
            }

            if (keyCode == KEY_ARROW_DOWN) {
                [sharedCandidates moveDown:self];
                _currentCandidateIndex++;
                return NO;
            }

            if (keyCode == KEY_ARROW_UP) {
                [sharedCandidates moveUp:self];
                _currentCandidateIndex--;
                return NO;
            }
        }

        if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch]) {
            if (!hasBufferedText) {
                [self appendToComposedBuffer:characters];
                [self commitCompositionWithoutSpace:sender];
                return YES;
            }

            if (isCandidatesVisible) { // use 1~9 digital numbers as selection keys
                int pressedNumber = characters.intValue;
                NSString *candidate;
                int pageSize = 9;
                if (_currentCandidateIndex <= pageSize) {
                    candidate = _candidates[pressedNumber - 1];
                } else {
                    candidate = _candidates[pageSize * (_currentCandidateIndex / pageSize - 1) + (_currentCandidateIndex % pageSize) +
                                            pressedNumber - 1];
                }
                [self cancelComposition];
                [self setComposedBuffer:candidate];
                [self setOriginalBuffer:candidate];
                [self commitComposition:sender];
                return YES;
            }
        }
    }

    if ([[NSCharacterSet punctuationCharacterSet] characterIsMember:ch] || [[NSCharacterSet symbolCharacterSet] characterIsMember:ch]) {
        if (hasBufferedText) {
            [self appendToComposedBuffer:characters];
            [self commitCompositionWithoutSpace:sender];
            return YES;
        }
    }

    return NO;
}

- (BOOL)isMojaveAndLaterSystem {
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    return (version.majorVersion == 10 && version.minorVersion > 13) || version.majorVersion > 10;
}

- (BOOL)deleteBackward:(id)sender {
    NSMutableString *originalText = [self originalBuffer];

    if (_insertionIndex > 0) {
        --_insertionIndex;

        NSString *convertedString = [originalText substringToIndex:originalText.length - 1];

        [self setComposedBuffer:convertedString];
        [self setOriginalBuffer:convertedString];

        [self showPreeditString:convertedString];

        if (convertedString && convertedString.length > 0) {
            [sharedCandidates updateCandidates];
            [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        } else {
            [self reset];
        }
        return YES;
    }
    return NO;
}

- (void)commitComposition:(id)sender {
    if (_pinyinMode || [self mixedInput]) {
        // server-driven commit (e.g. focus loss): flush the unconverted input
        NSString *rawInput = [rimeEngine rawInput:(RimeSessionId)_rimeSession];
        [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
        if (rawInput.length > 0) {
            [sender insertText:rawInput replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        }
        [self reset];
        return;
    }

    [self commitEnglishComposition:sender];
}

// English-mode commit, honoring the commitWordWithSpace preference.
- (void)commitEnglishComposition:(id)sender {
    NSString *text = [self composedBuffer];

    if (text == nil || text.length == 0) {
        text = [self originalBuffer];
    }

    BOOL commitWordWithSpace = [preference boolForKey:@"commitWordWithSpace"];

    if (!_pinyinMode && commitWordWithSpace && text.length > 0) {
        char firstChar = [text characterAtIndex:0];
        char lastChar = [text characterAtIndex:text.length - 1];
        if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:firstChar] && lastChar != '\'') {
            text = [NSString stringWithFormat:@"%@ ", text];
        }
    }

    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    [self reset];
}

- (void)commitCompositionWithoutSpace:(id)sender {
    NSString *text = [self composedBuffer];

    if (text == nil || text.length == 0) {
        text = [self originalBuffer];
    }

    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    [self reset];
}

- (void)reset {
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    _currentCandidateIndex = 1;
    [sharedCandidates clearSelection];
    [sharedCandidates hide];
    _candidates = [[NSMutableArray alloc] init];
    _rimePageCandidates = [[NSMutableArray alloc] init];
    _mixedRowIsEnglish = [[NSMutableArray alloc] init];
    _mixedRowRimeIndexes = [[NSMutableArray alloc] init];
    _panelHighlight = 0;
    [sharedCandidates setCandidateData:@[]];
    [_annotationWin setAnnotation:@""];
    [_annotationWin hideWindow];
}

- (NSMutableString *)composedBuffer {
    if (_composedBuffer == nil) {
        _composedBuffer = [[NSMutableString alloc] init];
    }
    return _composedBuffer;
}

- (void)setComposedBuffer:(NSString *)string {
    NSMutableString *buffer = [self composedBuffer];
    [buffer setString:string];
}

- (NSMutableString *)originalBuffer {
    if (_originalBuffer == nil) {
        _originalBuffer = [[NSMutableString alloc] init];
    }
    return _originalBuffer;
}

- (void)setOriginalBuffer:(NSString *)input {
    NSMutableString *buffer = [self originalBuffer];
    [buffer setString:input];
}

- (void)showPreeditString:(NSString *)input {
    NSDictionary *attrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, input.length)];
    NSAttributedString *attrString;

    NSString *originalBuff = [NSString stringWithString:[self originalBuffer]];
    if ([input.lowercaseString hasPrefix:originalBuff.lowercaseString]) {
        attrString = [[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@%@", originalBuff, [input substringFromIndex:originalBuff.length]]
                attributes:attrs];
    } else {
        attrString = [[NSAttributedString alloc] initWithString:input attributes:attrs];
    }

    [_currentClient setMarkedText:attrString
                   selectionRange:NSMakeRange(input.length, 0)
                 replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (void)originalBufferAppend:(NSString *)input client:(id)sender {
    NSMutableString *buffer = [self originalBuffer];
    [buffer appendString:input];
    _insertionIndex++;
    [self showPreeditString:buffer];
}

- (void)appendToComposedBuffer:(NSString *)input {
    NSMutableString *buffer = [self composedBuffer];
    [buffer appendString:input];
}

- (NSArray *)candidates:(id)sender {
    NSString *originalInput = [self originalBuffer];

    if (_pinyinMode) {
        // candidates are refreshed by rimeUpdate after each processed key
        return _candidates;
    }

    if ([self mixedInput]) {
        // Order the two blocks by the last committed language: the block
        // matching that language leads (up to 5 rows), the other fills the
        // rest of the 9-row page. Reads from _rimePageCandidates (kept
        // separate from _candidates) so repeated IMK callbacks can't
        // recombine an already-combined list; _mixedRowRimeIndexes remembers
        // which Rime page index each Chinese row shows, so selection stays
        // positionally correct even when duplicates are skipped.
        NSMutableArray *english = [NSMutableArray array];
        for (NSString *word in [engine getCandidates:originalInput]) {
            if (word.length > 0 && ![english containsObject:word]) {
                [english addObject:word];
            }
            if (english.count == 5) {
                break;
            }
        }
        NSMutableArray *chinese = [NSMutableArray array];
        NSMutableArray *chineseIndexes = [NSMutableArray array];
        [_rimePageCandidates enumerateObjectsUsingBlock:^(NSString *word, NSUInteger idx, BOOL *stop) {
            if (chinese.count >= 5) {
                *stop = YES;
                return;
            }
            if (word.length > 0 && ![english containsObject:word] && ![chinese containsObject:word]) {
                [chinese addObject:word];
                [chineseIndexes addObject:@(idx)];
            }
        }];

        NSMutableArray *combined = [NSMutableArray array];
        NSMutableArray *rowIsEnglish = [NSMutableArray array];
        NSMutableArray *rowRimeIndexes = [NSMutableArray array];
        void (^appendEnglish)(NSString *word) = ^(NSString *word) {
            [combined addObject:word];
            [rowIsEnglish addObject:@YES];
            [rowRimeIndexes addObject:@(NSNotFound)];
        };
        void (^appendChinese)(NSUInteger idx) = ^(NSUInteger idx) {
            [combined addObject:_rimePageCandidates[idx]];
            [rowIsEnglish addObject:@NO];
            [rowRimeIndexes addObject:@(idx)];
        };
        if (_lastCommittedWasChinese) {
            for (NSUInteger i = 0; i < chinese.count && combined.count < 9; i++) {
                appendChinese([chineseIndexes[i] integerValue]);
            }
            for (NSString *word in english) {
                if (combined.count >= 9) {
                    break;
                }
                appendEnglish(word);
            }
        } else {
            for (NSString *word in english) {
                if (combined.count >= 9) {
                    break;
                }
                appendEnglish(word);
            }
            for (NSUInteger i = 0; i < chinese.count && combined.count < 9; i++) {
                appendChinese([chineseIndexes[i] integerValue]);
            }
        }
        _mixedRowIsEnglish = rowIsEnglish;
        _mixedRowRimeIndexes = rowRimeIndexes;
        _candidates = combined;
        return combined;
    }

    NSArray *candidateList = [engine getCandidates:originalInput];

    _candidates = [NSMutableArray arrayWithArray:candidateList];
    return candidateList;
}

- (void)candidateSelectionChanged:(NSAttributedString *)candidateString {
    if ([preference boolForKey:@"useGridCandidatePanel"]) {
        [self applyGridSelectionString:candidateString.string];
        return;
    }

    if (_pinyinMode || [self mixedInput]) {
        // highlight state is owned by the input method; nothing to sync here
        return;
    }

    [self _updateComposedBuffer:candidateString];

    [self showPreeditString:candidateString.string];

    _insertionIndex = candidateString.length;

    BOOL showTranslation = [preference boolForKey:@"showTranslation"];
    if (showTranslation) {
        [self showAnnotation:candidateString];
    }
}

- (void)candidateSelected:(NSAttributedString *)candidateString {
    NSUInteger index = [_candidates indexOfObject:candidateString.string];
    if (index == NSNotFound) {
        return;
    }
    if (_pinyinMode || [self mixedInput]) {
        [self commitSelectedRow:(NSInteger)index withSpace:YES sender:_currentClient];
        return;
    }
    [self setComposedBuffer:_candidates[index]];
    [self commitEnglishComposition:_currentClient];
}

- (void)_updateComposedBuffer:(NSAttributedString *)candidateString {
    [self setComposedBuffer:candidateString.string];
}

- (void)activateServer:(id)sender {
    [sender overrideKeyboardWithKeyboardNamed:@"com.apple.keylayout.US"];

    if (_annotationWin == nil) {
        _annotationWin = [AnnotationWinController sharedController];
    }

    _currentCandidateIndex = 1;
    _candidates = [[NSMutableArray alloc] init];
}

- (void)deactivateServer:(id)sender {
    [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
    [self reset];
}

- (NSMenu *)menu {
    return [(InputApplicationDelegate *)NSApp.delegate menu];
}

- (void)showIMEPreferences:(id)sender {
    [self openUrl:@"http://localhost:62718/index.html"];
}

- (void)clickAbout:(NSMenuItem *)sender {
    [self openUrl:@"https://github.com/dongyuwei/hallelujahIM"];
}

- (void)clickUpgrade:(NSMenuItem *)sender {
    [self openUrl:@"https://github.com/dongyuwei/hallelujahIM/releases/latest"];
}

- (void)openUrl:(NSString *)url {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];

    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration new];
    configuration.promptsUserIfNeeded = YES;
    configuration.createsNewApplicationInstance = NO;

    [ws openURL:[NSURL URLWithString:url]
            configuration:configuration
        completionHandler:^(NSRunningApplication *_Nullable app, NSError *_Nullable error) {
            if (error) {
                NSLog(@"Failed to run the app: %@", error.localizedDescription);
            }
        }];
}

- (void)showAnnotation:(NSAttributedString *)candidateString {
    NSString *annotation = [engine getAnnotation:candidateString.string];
    if (annotation && annotation.length > 0) {
        [_annotationWin setAnnotation:annotation];
        [_annotationWin showWindow:[self calculatePositionOfTranslationWindow]];
    } else {
        [_annotationWin hideWindow];
    }
}

- (NSPoint)calculatePositionOfTranslationWindow {
    // Mac Cocoa ui default coordinate system: left-bottom, origin: (x:0, y:0) ↑→
    // see https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/CoordinateSystem.html
    // see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html
    // Notice: there is a System bug: candidateFrame.origin always be (0,0), so we can't depending on the origin point.
    NSRect candidateFrame = [sharedCandidates candidateFrame];

    // line-box of current input text: (width:1, height:17)
    NSRect lineRect;
    [_currentClient attributesForCharacterIndex:0 lineHeightRectangle:&lineRect];
    NSPoint cursorPoint = NSMakePoint(NSMinX(lineRect), NSMinY(lineRect));
    NSPoint positionPoint = NSMakePoint(NSMinX(lineRect), NSMinY(lineRect));
    positionPoint.x = positionPoint.x + candidateFrame.size.width;
    NSScreen *currentScreen = [NSScreen currentScreenForMouseLocation];
    NSPoint currentPoint = [currentScreen convertPointToScreenCoordinates:cursorPoint];
    NSRect rect = currentScreen.frame;
    int screenWidth = (int)rect.size.width;
    int marginToCandidateFrame = 20;
    int annotationWindowWidth = _annotationWin.width + marginToCandidateFrame;
    int lineHeight = lineRect.size.height; // 17px

    if (screenWidth - currentPoint.x >= candidateFrame.size.width) {
        // safe distance to display candidateFrame at current cursor's left-side.
        if (screenWidth - currentPoint.x < candidateFrame.size.width + annotationWindowWidth) {
            positionPoint.x = positionPoint.x - candidateFrame.size.width - annotationWindowWidth;
        }
    } else {
        // assume candidateFrame will display at current cursor's right-side.
        positionPoint.x = screenWidth - candidateFrame.size.width - annotationWindowWidth;
    }
    if (currentPoint.y >= candidateFrame.size.height) {
        positionPoint.y = positionPoint.y - 8; // Both 8 and 3 are magic numbers to adjust the position
    } else {
        positionPoint.y = positionPoint.y + candidateFrame.size.height + lineHeight + 3;
    }

    return positionPoint;
}

@end
