#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

#import "CandidatePanel.h"
#import "InputApplicationDelegate.h"
#import "InputController.h"
#import "NSScreen+PointConversion.h"
#import "RimeEngine.h"
#import "RimeKeymap.h"

extern CandidatePanel *sharedCandidates;
extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern RimeEngine *rimeEngine;

typedef NSInteger KeyCode;
static const KeyCode KEY_RETURN = 36, KEY_SPACE = 49, KEY_DELETE = 51, KEY_ESC = 53, KEY_ARROW_DOWN = 125, KEY_ARROW_UP = 126,
                     KEY_ARROW_LEFT = 123, KEY_ARROW_RIGHT = 124, KEY_RIGHT_SHIFT = 60, KEY_RIGHT_COMMAND = 54;

@interface InputController () <CandidatePanelDelegate>

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

        // Right Command key: toggle pinyin mode
        if (modifiers == 0 && _lastEventTypes[1] == NSEventTypeFlagsChanged && event.keyCode == KEY_RIGHT_COMMAND) {
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

        if (_pinyinMode) {
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

// Pinyin mode: Rime drives the composition; the candidate panel mirrors each
// page of Chinese candidates.
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

// Digits pick a candidate at a selectable key position: the column within
// the active row in grid mode, the window offset in vertical mode.
- (BOOL)onCandidateDigitKey:(NSString *)chars sender:(id)sender {
    int digit = chars.intValue;
    if (digit < 1 || digit > 9) {
        return NO; // not a selectable key; let Rime/app handle the digit
    }
    NSInteger index = [sharedCandidates indexForDigit:digit];
    if (index == NSNotFound || index >= (NSInteger)_candidates.count) {
        return NO;
    }
    [self commitSelectedRow:index withSpace:YES sender:sender];
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
    if (down) {
        [sharedCandidates moveSelectionDown];
    } else {
        [sharedCandidates moveSelectionUp];
    }
    [self syncHighlightFromPanel];
    return YES;
}

// Arrow-key navigation for the grid layout. The panel owns the geometry
// (5 columns per row, first down press expands, up collapses at row 0,
// left/right wrap within the active row). Arrow keys are always consumed in
// grid mode so the event never falls through to the vertical path. Returns NO
// only when the grid panel preference is off.
- (BOOL)navigateGridPanelWithKeyCode:(NSInteger)keyCode sender:(id)sender {
    if (![preference boolForKey:@"useGridCandidatePanel"]) {
        return NO;
    }
    if (_candidates.count == 0) {
        return NO;
    }
    switch (keyCode) {
    case KEY_ARROW_LEFT:
        [sharedCandidates gridMoveLeft];
        break;
    case KEY_ARROW_RIGHT:
        [sharedCandidates gridMoveRight];
        break;
    case KEY_ARROW_UP:
        [sharedCandidates gridMoveUp];
        break;
    case KEY_ARROW_DOWN:
        [sharedCandidates gridMoveDown];
        break;
    default:
        return NO;
    }
    [self syncHighlightFromPanel];
    return YES;
}
// Mirrors the panel's highlight into the composition state so space, enter
// and digits commit what the user sees (English mode commits _composedBuffer;
// pinyin commits straight from _panelHighlight).
- (void)syncHighlightFromPanel {
    _panelHighlight = sharedCandidates.selectedIndex;
    if (_pinyinMode || _panelHighlight < 0 || _panelHighlight >= (NSInteger)_candidates.count) {
        return;
    }
    NSString *word = _candidates[_panelHighlight];
    [self setComposedBuffer:word];
    [self showPreeditString:word];
    _insertionIndex = word.length;

    // The old IMKCandidates drove the translation popup through the
    // candidateSelectionChanged: delegate callback, which the custom panel
    // never fires; show the annotation for the highlighted word directly.
    BOOL showTranslation = [preference boolForKey:@"showTranslation"];
    if (showTranslation) {
        [self showAnnotation:[[NSAttributedString alloc] initWithString:word]];
    }
}

// Commits the candidate shown on the given panel row by its Rime page index
// (pinyin) or the English commit path (English mode).
- (void)commitSelectedRow:(NSInteger)row withSpace:(BOOL)withSpace sender:(id)sender {
    if (row < 0 || row >= (NSInteger)_candidates.count) {
        return;
    }
    [rimeEngine selectCandidateOnCurrentPage:(RimeSessionId)_rimeSession index:row];
    [self rimeUpdate:sender];
}

// Single refresh point after every processed key: deliver pending commit,
// mirror Rime's preedit into inline marked text, and feed the candidate panel
// with the current page of candidates.
- (void)rimeUpdate:(id)sender {
    NSString *commitText = [rimeEngine commitText:(RimeSessionId)_rimeSession];
    if (commitText.length > 0) {
        [sender insertText:commitText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }

    NSArray<RimeCandidateItem *> *rimeCandidates = [rimeEngine candidates:(RimeSessionId)_rimeSession];
    _candidates = [NSMutableArray array];
    for (RimeCandidateItem *candidate in rimeCandidates) {
        [_candidates addObject:candidate.text];
    }

    NSInteger selStart = 0, selLength = 0, caretPos = 0;
    NSString *preedit = [rimeEngine preedit:(RimeSessionId)_rimeSession selStart:&selStart selLength:&selLength caretPos:&caretPos];
    if (preedit.length == 0) {
        [sharedCandidates hide];
        _panelHighlight = 0;
        return;
    }

    [sharedCandidates updateCandidates:_candidates];
    [sharedCandidates showAtClient:_currentClient];
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

        // The old IMKCandidates used to pull candidates through the
        // candidates: callback on updateCandidates; the custom panel never
        // does, so request them here.
        [self candidates:sender];
        [sharedCandidates updateCandidates:_candidates];
        [sharedCandidates showAtClient:_currentClient];
        [self syncHighlightFromPanel];
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
                [sharedCandidates moveSelectionDown];
                _currentCandidateIndex++;
                [self syncHighlightFromPanel];
                return YES;
            }

            if (keyCode == KEY_ARROW_UP) {
                [sharedCandidates moveSelectionUp];
                _currentCandidateIndex--;
                [self syncHighlightFromPanel];
                return YES;
            }
        }

        if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch]) {
            if (!hasBufferedText) {
                [self appendToComposedBuffer:characters];
                [self commitCompositionWithoutSpace:sender];
                return YES;
            }

            if (isCandidatesVisible) { // digits are selection keys
                int pressedNumber = characters.intValue;
                NSInteger index = [sharedCandidates indexForDigit:pressedNumber];
                if (index == NSNotFound || index >= (NSInteger)_candidates.count) {
                    return NO;
                }
                NSString *candidate = _candidates[index];
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
            [self candidates:sender]; // custom panel does not pull candidates itself
            [sharedCandidates updateCandidates:_candidates];
            [sharedCandidates showAtClient:_currentClient];
            [self syncHighlightFromPanel];
        } else {
            [self reset];
        }
        return YES;
    }
    return NO;
}

- (void)commitComposition:(id)sender {
    if (_pinyinMode) {
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
    [sharedCandidates hide];
    [sharedCandidates updateCandidates:@[]];
    _candidates = [[NSMutableArray alloc] init];
    _panelHighlight = 0;
    [sharedCandidates setAnnotation:@""];
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

    NSArray *candidateList = [engine getCandidates:originalInput];

    _candidates = [NSMutableArray arrayWithArray:candidateList];
    return candidateList;
}

- (void)candidateSelectionChanged:(NSAttributedString *)candidateString {
    if (_pinyinMode) {
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

- (void)candidatePanel:(CandidatePanel *)panel clickedIndex:(NSInteger)index {
    [self commitSelectedRow:index withSpace:YES sender:_currentClient];
}

- (void)candidateSelected:(NSAttributedString *)candidateString {
    NSUInteger index = [_candidates indexOfObject:candidateString.string];
    if (index == NSNotFound) {
        return;
    }
    if (_pinyinMode) {
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

    sharedCandidates.delegate = self;
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
    // The gloss lives inside the candidate panel now: it grows a footer row
    // under the grid/list instead of opening a second window. Both vertical
    // and grid layouts render it the same way, so the separate annotation
    // window is retired.
    NSString *annotation = [engine getAnnotation:candidateString.string];
    [sharedCandidates setAnnotation:annotation ?: @""];
}

@end
