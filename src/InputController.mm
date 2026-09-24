#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

#import "CandidatePanel.h"
#import "InputApplicationDelegate.h"
#import "InputController.h"
#import "MarkedTextState.h"
#import "NSScreen+PointConversion.h"
#import "PinyinCandidateRows.h"
#import "RimeEngine.h"
#import "RimeKeymap.h"

extern CandidatePanel *sharedCandidates;
extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern RimeEngine *rimeEngine;

typedef NSInteger KeyCode;
static const KeyCode KEY_RETURN = 36, KEY_SPACE = 49, KEY_DELETE = 51, KEY_ESC = 53, KEY_ARROW_DOWN = 125, KEY_ARROW_UP = 126,
                     KEY_ARROW_LEFT = 123, KEY_ARROW_RIGHT = 124, KEY_RIGHT_COMMAND = 54;

@interface InputController () <CandidatePanelDelegate>

// Marked-text bookkeeping. One keystroke hands the client the same string twice
// (buffer append, then highlight sync); MarkedTextState owns the skip rules and
// is unit-tested, so the checks here stay one-liners.
- (MarkedTextState *)markedText;
- (void)setMarkedTextIfChanged:(NSAttributedString *)attrString
                selectionRange:(NSRange)selectionRange
              replacementRange:(NSRange)replacementRange;
- (void)forgetMarkedText;

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

        // Right Command key: cycle between hallelujah-english, raw-english
        // and pinyin input modes.
        if (modifiers == 0 && _lastEventTypes[1] == NSEventTypeFlagsChanged && event.keyCode == KEY_RIGHT_COMMAND) {
            [self cycleInputMode:sender];
        }
        break;
    case NSEventTypeKeyDown:
        if (_inputMode == InputModeRawEnglish) {
            break;
        }

        // ignore Command+X hotkeys.
        if (modifiers & NSEventModifierFlagCommand)
            break;

        if (_inputMode == InputModePinyin) {
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

// Right Command cycles: hallelujah-english -> pinyin -> raw-english -> back.
// Pinyin is skipped unless the enablePinyinInput preference is on. Switching
// away from a composing mode flushes what was typed so nothing is lost:
// hallelujah-english commits its buffered word, pinyin flushes Rime's
// unconverted input as plain text.
- (void)cycleInputMode:(id)sender {
    switch (_inputMode) {
    case InputModeHallelujahEnglish: {
        NSString *bufferedText = [self originalBuffer];
        if (bufferedText && bufferedText.length > 0) {
            [self cancelComposition];
            [self commitCompositionWithoutSpace:sender];
        }
        break;
    }
    case InputModeRawEnglish:
        break; // nothing buffered; keys pass straight through
    case InputModePinyin: {
        NSString *rawInput = [rimeEngine rawInput:(RimeSessionId)_rimeSession];
        [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
        if (rawInput.length > 0) {
            [sender insertText:rawInput replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        }
        break;
    }
    }
    InputMode next = (InputMode)((_inputMode + 1) % 3);
    if (next == InputModePinyin && ![preference boolForKey:@"enablePinyinInput"]) {
        next = InputModeRawEnglish;
    }
    _inputMode = next;
    [self reset];
}

// Pinyin mode: Rime drives the composition; the candidate panel mirrors each
// page of Chinese candidates with the raw input spliced in at the configured
// candidate position (PinyinCandidateRows owns the row model).
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
    // arrows move the highlight. Rime only builds the composition; the row at
    // the configured raw-input position commits the typed input, and the
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
// Enter commits it without a trailing space. A fresh page highlights row 0,
// which is the raw input only when it is configured as the first candidate.
// With no candidates left, hand the key back to Rime.
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
// Arrow-key navigation for the grid layout. The panel owns the geometry
// (5 columns per row, first down press expands, up collapses at row 0,
// left/right wrap within the active row). Arrow keys are always consumed while
// the panel is visible so the event never falls through to the client.
- (BOOL)navigateGridPanelWithKeyCode:(NSInteger)keyCode sender:(id)sender {
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
// pinyin commits straight from _panelHighlight). Used by the navigation paths,
// which only move the highlight.
- (void)syncHighlightFromPanel {
    _panelHighlight = sharedCandidates.selectedIndex;
    [self applyHighlightToComposition];

    // The old IMKCandidates drove the translation popup through the
    // candidateSelectionChanged: delegate callback, which the custom panel
    // never fires; show the annotation for the highlighted word directly.
    NSString *annotation = [self annotationForHighlightedCandidate];
    if (annotation != nil) {
        [sharedCandidates setAnnotation:annotation];
    }
}

// Buffer and inline preedit for the highlighted candidate. Split out of
// syncHighlightFromPanel because the per-keystroke path passes the gloss to the
// panel as part of a single update instead of triggering a second one.
- (void)applyHighlightToComposition {
    if (_inputMode == InputModePinyin || _panelHighlight < 0 || _panelHighlight >= (NSInteger)_candidates.count) {
        return;
    }
    NSString *word = _candidates[_panelHighlight];
    [self setComposedBuffer:word];
    [self showPreeditString:word];
    _insertionIndex = word.length;
}

// Gloss for the highlighted candidate, or nil when there is nothing to change:
// pinyin mode shows none, and with the translation preference off the panel
// keeps whatever it had (the pre-existing behaviour).
- (NSString *)annotationForHighlightedCandidate {
    if (_inputMode == InputModePinyin || ![preference boolForKey:@"showTranslation"]) {
        return nil;
    }
    if (_panelHighlight < 0 || _panelHighlight >= (NSInteger)_candidates.count) {
        return @"";
    }
    return [engine getAnnotation:_candidates[_panelHighlight]] ?: @"";
}

// Commits the candidate shown on the given panel row. In pinyin mode the row
// at the configured raw-input position commits the raw input as plain text,
// and the other rows select Rime candidates through the row mapping owned by
// _pinyinRows.
- (void)commitSelectedRow:(NSInteger)row withSpace:(BOOL)withSpace sender:(id)sender {
    if (row < 0 || row >= (NSInteger)_candidates.count) {
        return;
    }
    if (_inputMode == InputModePinyin) {
        if ([_pinyinRows rowIsRawInput:row]) {
            [self commitRimeRawInput:withSpace sender:sender];
            return;
        }
        [rimeEngine selectCandidateOnCurrentPage:(RimeSessionId)_rimeSession index:[_pinyinRows rimeIndexForRow:row]];
    } else {
        [rimeEngine selectCandidateOnCurrentPage:(RimeSessionId)_rimeSession index:row];
    }
    [self rimeUpdate:sender];
}

// Commits the raw pinyin input as plain text - pinyin panel row 0, selected
// with space, enter or 1. Mirrors the English commit: the commitWordWithSpace
// preference decides the trailing space, and input ending with the pinyin
// syllable separator gets none, like the English apostrophe rule.
- (void)commitRimeRawInput:(BOOL)withSpace sender:(id)sender {
    NSString *rawInput = [rimeEngine rawInput:(RimeSessionId)_rimeSession];
    [rimeEngine clearComposition:(RimeSessionId)_rimeSession];
    if (rawInput.length > 0) {
        NSString *text = rawInput;
        if (withSpace && [preference boolForKey:@"commitWordWithSpace"]) {
            unichar firstChar = [text characterAtIndex:0];
            unichar lastChar = [text characterAtIndex:text.length - 1];
            if (![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:firstChar] && lastChar != '\'') {
                text = [NSString stringWithFormat:@"%@ ", text];
            }
        }
        [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }
    [self reset];
}

// Single refresh point after every processed key: deliver pending commit,
// mirror Rime's preedit into inline marked text, and feed the candidate panel.
// The panel rows come from PinyinCandidateRows: Rime's current page with the
// raw input spliced in at the configured candidate position, so the digit
// matching that position commits what was typed.
- (void)rimeUpdate:(id)sender {
    NSString *commitText = [rimeEngine commitText:(RimeSessionId)_rimeSession];
    if (commitText.length > 0) {
        [sender insertText:commitText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        // The client's composition is gone; a later composition may legitimately
        // repeat this string, so it must be delivered again.
        [self forgetMarkedText];
    }

    NSMutableArray *rimeTexts = [NSMutableArray array];
    for (RimeCandidateItem *candidate in [rimeEngine candidates:(RimeSessionId)_rimeSession]) {
        [rimeTexts addObject:candidate.text];
    }
    _pinyinRows = [[PinyinCandidateRows alloc] initWithRawInput:[rimeEngine rawInput:(RimeSessionId)_rimeSession]
                                                 rimeCandidates:rimeTexts
                                              preferredPosition:[preference integerForKey:@"pinyinRawInputCandidatePosition"]];
    _candidates = [_pinyinRows.rows mutableCopy];

    NSInteger selStart = 0, selLength = 0, caretPos = 0;
    NSString *preedit = [rimeEngine preedit:(RimeSessionId)_rimeSession selStart:&selStart selLength:&selLength caretPos:&caretPos];
    if (preedit.length == 0) {
        [sharedCandidates hide];
        _panelHighlight = 0;
        [self forgetMarkedText];
        return;
    }

    // One panel update for the whole keystroke. Pinyin shows no gloss, so the
    // annotation is left as it is.
    [sharedCandidates updateCandidates:_candidates annotation:nil atClient:_currentClient];
    // selection state is owned by the input method; a fresh page starts at row 0
    _panelHighlight = 0;

    NSDictionary *rawAttrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, preedit.length)];
    NSDictionary *convertedAttrs = [self markForStyle:kTSMHiliteConvertedText atRange:NSMakeRange(0, preedit.length)];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:preedit attributes:rawAttrs];
    if (selLength > 0) {
        [attrString setAttributes:convertedAttrs range:NSMakeRange(selStart, selLength)];
    }
    [self setMarkedTextIfChanged:attrString selectionRange:NSMakeRange(caretPos, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
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
        // A fresh page starts at row 0, and the gloss for that row goes in with
        // the same panel update, so the panel is laid out once per keystroke
        // instead of three times.
        _panelHighlight = 0;
        [sharedCandidates updateCandidates:_candidates annotation:[self annotationForHighlightedCandidate] atClient:_currentClient];
        [self applyHighlightToComposition];
        return YES;
    }

    BOOL isCandidatesVisible = [sharedCandidates isVisible];
    if (isCandidatesVisible) {
        if (keyCode == KEY_ARROW_DOWN || keyCode == KEY_ARROW_UP || keyCode == KEY_ARROW_LEFT || keyCode == KEY_ARROW_RIGHT) {
            if ([self navigateGridPanelWithKeyCode:keyCode sender:sender]) {
                return YES;
            }
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

    if ([[NSCharacterSet punctuationCharacterSet] characterIsMember:ch] || [[NSCharacterSet symbolCharacterSet] characterIsMember:ch]) {
        if (hasBufferedText) {
            [self appendToComposedBuffer:characters];
            [self commitCompositionWithoutSpace:sender];
            return YES;
        }
    }

    return NO;
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
            _panelHighlight = 0;
            [sharedCandidates updateCandidates:_candidates annotation:[self annotationForHighlightedCandidate] atClient:_currentClient];
            [self applyHighlightToComposition];
        } else {
            [self reset];
        }
        return YES;
    }
    return NO;
}

- (void)commitComposition:(id)sender {
    if (_inputMode == InputModePinyin) {
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

    if (_inputMode != InputModePinyin && commitWordWithSpace && text.length > 0) {
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
    [self forgetMarkedText];
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    [sharedCandidates hide];
    [sharedCandidates updateCandidates:@[]];
    _candidates = [[NSMutableArray alloc] init];
    _pinyinRows = nil;
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
    NSRange selectionRange = NSMakeRange(input.length, 0);
    NSString *originalBuff = [self originalBuffer];
    NSString *display = input;
    if ([input.lowercaseString hasPrefix:originalBuff.lowercaseString]) {
        display = [NSString stringWithFormat:@"%@%@", originalBuff, [input substringFromIndex:originalBuff.length]];
    }
    MarkedTextState *markedText = [self markedText];
    if ([markedText isCurrentForString:display selectionRange:selectionRange client:_currentClient]) {
        return; // the client already shows this, so skip the style lookup too
    }

    NSDictionary *attrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, input.length)];
    [markedText recordString:display selectionRange:selectionRange client:_currentClient];
    [_currentClient setMarkedText:[[NSAttributedString alloc] initWithString:display attributes:attrs]
                   selectionRange:selectionRange
                 replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (MarkedTextState *)markedText {
    if (_markedText == nil) {
        _markedText = [[MarkedTextState alloc] init];
    }
    return _markedText;
}

- (void)setMarkedTextIfChanged:(NSAttributedString *)attrString
                selectionRange:(NSRange)selectionRange
              replacementRange:(NSRange)replacementRange {
    MarkedTextState *markedText = [self markedText];
    if ([markedText isCurrentForString:attrString.string selectionRange:selectionRange client:_currentClient]) {
        return;
    }
    [markedText recordString:attrString.string selectionRange:selectionRange client:_currentClient];
    [_currentClient setMarkedText:attrString selectionRange:selectionRange replacementRange:replacementRange];
}

// The client's composition was committed or cancelled; whatever it showed can
// no longer be assumed to still be there.
- (void)forgetMarkedText {
    [[self markedText] forget];
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

    if (_inputMode == InputModePinyin) {
        // candidates are refreshed by rimeUpdate after each processed key
        return _candidates;
    }

    NSArray *candidateList = [engine getCandidates:originalInput];

    _candidates = [NSMutableArray arrayWithArray:candidateList];
    return candidateList;
}

- (void)candidateSelectionChanged:(NSAttributedString *)candidateString {
    if (_inputMode == InputModePinyin) {
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
    if (_inputMode == InputModePinyin) {
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

    // A freshly activated client shows no marked text from us.
    [self forgetMarkedText];
    sharedCandidates.delegate = self;
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
    // under the grid instead of opening a second window. The separate
    // annotation window is retired.
    NSString *annotation = [engine getAnnotation:candidateString.string];
    [sharedCandidates setAnnotation:annotation ?: @""];
}

@end
