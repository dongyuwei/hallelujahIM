#import "InputController.h"
#import "InputApplicationDelegate.h"
#import "NSScreen+PointConversion.h"
#import "marisa.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

extern IMKCandidates *sharedCandidates;
extern marisa::Trie trie;
extern NSMutableDictionary *wordsWithFrequencyAndTranslation;
extern NSDictionary *substitutions;
extern NSDictionary *pinyinDict;
extern NSUserDefaults *preference;

typedef NSInteger KeyCode;
static const KeyCode KEY_RETURN = 36, KEY_SPACE = 49, KEY_DELETE = 51, KEY_ESC = 53, KEY_ARROW_DOWN = 125, KEY_ARROW_UP = 126;

@implementation InputController

- (NSUInteger)recognizedEvents:(id)sender {
    return NSKeyDownMask | NSFlagsChangedMask;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    NSUInteger modifiers = [event modifierFlags];
    bool handled = NO;
    switch ([event type]) {
    case NSFlagsChanged:
        if (_lastEventTypes[1] == NSFlagsChanged && _lastModifiers[1] == modifiers) {
            return YES;
        }

        if (modifiers == 0 && _lastEventTypes[1] == NSFlagsChanged && _lastModifiers[1] == NSShiftKeyMask &&
            !(_lastModifiers[0] & NSShiftKeyMask)) {

            _defaultEnglishMode = !_defaultEnglishMode;
            if (_defaultEnglishMode) {
                NSString *bufferedText = [self originalBuffer];
                if (bufferedText && [bufferedText length] > 0) {
                    [self cancelComposition];
                    [self commitComposition:sender];
                }
            }
        }
        break;
    case NSKeyDown:
        if (_defaultEnglishMode) {
            break;
        }

        // ignore Command+X hotkeys.
        if (modifiers & NSCommandKeyMask)
            break;

        handled = [self onKeyEvent:event client:sender];
        break;
    default:
        break;
    }

    _lastModifiers[0] = _lastModifiers[1];
    _lastEventTypes[0] = _lastEventTypes[1];
    _lastModifiers[1] = modifiers;
    _lastEventTypes[1] = [event type];
    return handled;
}

- (BOOL)onKeyEvent:(NSEvent *)event client:(id)sender {
    _currentClient = sender;
    NSInteger keyCode = [event keyCode];
    NSString *characters = [event characters];

    NSString *bufferedText = [self originalBuffer];
    bool hasBufferedText = bufferedText && [bufferedText length] > 0;

    //    NSLog(@"text:%@, keycode:%ld,  %ld, bufferedText:%@", string, (long)keyCode,
    //          [event modifierFlags] & NSShiftKeyMask, bufferedText);

    if (keyCode == KEY_DELETE) {
        if (hasBufferedText) {
            return [self deleteBackward:sender];
        }

        return NO;
    }

    if (keyCode == KEY_RETURN) {
        if (hasBufferedText) {
            [self commitComposition:sender];
            return YES;
        }
        return NO;
    }

    if (keyCode == KEY_SPACE) {
        if (hasBufferedText) {
            [self appendToComposedBuffer:@" "];
            [self commitComposition:sender];
            return YES;
        }
        return NO;
    }

    if (keyCode == KEY_ESC) {
        if (hasBufferedText) {
            [self cancelComposition];
            [self setComposedBuffer:@""];
            [self setOriginalBuffer:@""];
            [self commitComposition:sender];
        }
        return NO;
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
                [self commitComposition:sender];
                return YES;
            }

            if (isCandidatesVisible) { // use 1~9 digital numbers as selection keys
                int pressedNumber = [characters intValue];
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
            [self commitComposition:sender];
            return YES;
        }
    }

    return NO;
}

- (BOOL)isMojaveAndLaterSystem {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    return version.majorVersion == 10 && version.minorVersion > 13;
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
    NSString *text = [self composedBuffer];

    if (text == nil || [text length] == 0) {
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
    [sharedCandidates setCandidateData:@[]];
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
    NSDictionary *attrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, [input length])];
    NSAttributedString *attrString;

    NSString *originalBuff = [NSString stringWithString:[self originalBuffer]];
    if ([[input lowercaseString] hasPrefix:[originalBuff lowercaseString]]) {
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
    NSString *buffer = [originalInput lowercaseString];
    NSMutableArray *result = [[NSMutableArray alloc] init];

    if (buffer && buffer.length > 0) {
        if (substitutions && substitutions[buffer]) {
            [result addObject:substitutions[buffer]];
        }

        NSMutableArray *filtered = [self queryTrie:buffer];
        if (filtered && filtered.count > 0) {
            NSArray *sorted = [self sortByFrequency:filtered];
            [result addObjectsFromArray:sorted];
        } else {
            [result addObjectsFromArray:[self getSuggestionOfSpellChecker:buffer]];
        }

        if (pinyinDict && pinyinDict[buffer]) {
            [result addObjectsFromArray:pinyinDict[buffer]];
        }

        if (result.count > 50) {
            result = [NSMutableArray arrayWithArray:[result subarrayWithRange:NSMakeRange(0, 49)]];
        }

        [result removeObject:buffer];
        [result insertObject:buffer atIndex:0];
    }

    NSMutableArray *result2 = [[NSMutableArray alloc] init];
    for (NSString *word in result) {
        // case sensitive input
        if ([word hasPrefix:buffer]) {
            [result2 addObject:[NSString stringWithFormat:@"%@%@", originalInput, [word substringFromIndex:originalInput.length]]];
        } else {
            [result2 addObject:word];
        }
    }
    _candidates = [NSMutableArray arrayWithArray:result2];
    return [NSArray arrayWithArray:result2];
}

- (NSMutableArray *)queryTrie:(NSString *)buffer {
    marisa::Agent agent;
    const char *query = [buffer cStringUsingEncoding:[NSString defaultCStringEncoding]];
    agent.set_query(query);

    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    while (trie.predictive_search(agent)) {
        const marisa::Key key = agent.key();
        NSString *word = [[NSString alloc] initWithBytes:key.ptr() length:key.length() encoding:NSASCIIStringEncoding];
        [filtered addObject:word];
    }
    return filtered;
}

- (NSArray *)getSuggestionOfSpellChecker:(NSString *)buffer {
    NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
    NSRange range = NSMakeRange(0, [buffer length]);
    return [checker guessesForWordRange:range inString:buffer language:@"en" inSpellDocumentWithTag:0];
}

- (NSArray *)sortByFrequency:(NSArray *)filtered {
    NSArray *sorted = [filtered sortedArrayUsingComparator:^NSComparisonResult(id word1, id word2) {
        NSDictionary *dict1 = [wordsWithFrequencyAndTranslation objectForKey:word1];
        NSDictionary *dict2 = [wordsWithFrequencyAndTranslation objectForKey:word2];
        int n = [[dict1 objectForKey:@"frequency"] intValue] - [[dict2 objectForKey:@"frequency"] intValue];
        if (n > 0) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        if (n < 0) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];

    return sorted;
}

- (void)candidateSelectionChanged:(NSAttributedString *)candidateString {
    [self _updateComposedBuffer:candidateString];

    [self showPreeditString:[candidateString string]];

    _insertionIndex = [candidateString length];

    BOOL showTranslation = [preference boolForKey:@"showTranslation"];
    if (showTranslation) {
        [self showAnnotation:candidateString];
    }
}

- (void)candidateSelected:(NSAttributedString *)candidateString {
    [self _updateComposedBuffer:candidateString];

    [self commitComposition:_currentClient];
}

- (void)_updateComposedBuffer:(NSAttributedString *)candidateString {
    [self setComposedBuffer:[candidateString string]];
}

- (void)activateServer:(id)sender {
    if (_annotationWin == nil) {
        _annotationWin = [AnnotationWinController sharedController];
    }
    _currentCandidateIndex = 1;
    _candidates = [[NSMutableArray alloc] init];
}

- (void)deactivateServer:(id)sender {
    [self reset];
}

- (NSMenu *)menu {
    return [[NSApp delegate] performSelector:NSSelectorFromString(@"menu")];
}

- (void)showIMEPreferences:(id)sender {
    [self openUrl:@"http://localhost:62718/index.html"];
}

- (void)clickAbout:(NSMenuItem *)sender {
    [self openUrl:@"https://github.com/dongyuwei/hallelujahIM"];
}

- (void)openUrl:(NSString *)url {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws openURLs:@[ [NSURL URLWithString:url] ]
               withAppBundleIdentifier:@"com.apple.Safari"
                               options:NSWorkspaceLaunchDefault
        additionalEventParamDescriptor:NULL
                     launchIdentifiers:NULL];
}

- (void)showAnnotation:(NSAttributedString *)candidateString {
    NSArray *translation = [self getTranslations:candidateString];
    if (translation && translation.count > 0) {
        NSString *translationText;
        NSString *phoneticSymbol = [self getPhoneticSymbolOfWord:candidateString];
        if ([phoneticSymbol length] > 0) {
            NSArray *list = @[ [NSString stringWithFormat:@"[%@]", phoneticSymbol] ];
            translationText = [[list arrayByAddingObjectsFromArray:translation] componentsJoinedByString:@"\n"];
        } else {
            translationText = [translation componentsJoinedByString:@"\n"];
        }
        NSRect candidateFrame = [sharedCandidates candidateFrame]; // system bug: candidateFrame.origin always be (0,0)
        NSRect lineRect;                                           // line-box of current input text: (width:1, height:17)
        [_currentClient attributesForCharacterIndex:0 lineHeightRectangle:&lineRect];
        NSPoint cursorPoint = NSMakePoint(NSMinX(lineRect), NSMinY(lineRect));
        NSPoint positionPoint = NSMakePoint(NSMinX(lineRect), NSMinY(lineRect));
        positionPoint.x = positionPoint.x + candidateFrame.size.width;
        NSScreen *currentScreen = [NSScreen currentScreenForMouseLocation];
        NSPoint currentPoint = [currentScreen convertPointToScreenCoordinates:cursorPoint];
        NSRect rect = [currentScreen frame];
        int screenWidth = (int)rect.size.width;
        int screenHeight = (int)rect.size.height;
        int marginToCandidateFrame = 20;
        int annotationWindowWidth = _annotationWin.width + marginToCandidateFrame;
        int lineHeight = lineRect.size.height; // 17px
        //        Mac Cocoa ui default coordinate system: right-top (x-y), origin: (x:0, y:0)
        if (screenWidth - currentPoint.x >=
            candidateFrame.size.width) { // safe distance to display candidateFrame at current cursor's left-side.
            if (screenWidth - currentPoint.x < candidateFrame.size.width + annotationWindowWidth) {
                positionPoint.x = positionPoint.x - candidateFrame.size.width - annotationWindowWidth;
            }
        } else {
            // assume candidateFrame will display at current cursor's right-side.
            positionPoint.x = screenWidth - candidateFrame.size.width - annotationWindowWidth;
        }

        if (currentPoint.y >= candidateFrame.size.height + lineHeight) {
            // safe distance to dispaly candidateFrame
            positionPoint.y = positionPoint.y - 6;
        } else {
            positionPoint.y = positionPoint.y + candidateFrame.size.height + lineHeight;
        }
        [_annotationWin setAnnotation:translationText];
        [_annotationWin showWindow:positionPoint];
    } else {
        [_annotationWin hideWindow];
    }
}

- (NSArray *)getTranslations:(NSAttributedString *)candidate {
    NSString *word = [[candidate string] lowercaseString];
    return [[wordsWithFrequencyAndTranslation objectForKey:word] objectForKey:@"translation"];
}

- (NSString *)getPhoneticSymbolOfWord:(NSAttributedString *)candidateString {
    if (candidateString && candidateString.length > 3) {
        NSString *word = [[candidateString string] lowercaseString];
        return [[wordsWithFrequencyAndTranslation objectForKey:word] objectForKey:@"ipa"];
    }
    return nil;
}

@end
