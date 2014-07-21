#import "InputController.h"
#import "NDTrie.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

extern IMKCandidates *sharedCandidates;
extern NDMutableTrie*  trie;
extern NSDictionary* wordsWithFrequency;
extern BOOL defaultEnglishMode;
extern NSMutableDictionary* passwordDict;


typedef NSInteger KeyCode;
static const KeyCode
KEY_RETURN = 36,
KEY_DELETE = 51,
KEY_ESC = 53,
KEY_BACKSPACE = 117,
KEY_MOVE_LEFT = 123,
KEY_MOVE_RIGHT = 124,
KEY_MOVE_DOWN = 125;


@implementation InputController

-(NSUInteger)recognizedEvents:(id)sender{
    return NSKeyDownMask | NSFlagsChangedMask;
}

/*
Implement one of the three ways to receive input from the client. 
Here are the three approaches:
                 
 1.  Support keybinding.  
        In this approach the system takes each keydown and trys to map the keydown to an action method that the input method has implemented.  If an action is found the system calls didCommandBySelector:client:.  If no action method is found inputText:client: is called.  An input method choosing this approach should implement
        -(BOOL)inputText:(NSString*)string client:(id)sender;
        -(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender;
        
2. Receive all key events without the keybinding, but do "unpack" the relevant text data.
        Key events are broken down into the Unicodes, the key code that generated them, and modifier flags.  This data is then sent to the input method's inputText:key:modifiers:client: method.  For this approach implement:
        -(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender;
        
3. Receive events directly from the Text Services Manager as NSEvent objects.  For this approach implement:
        -(BOOL)handleEvent:(NSEvent*)event client:(id)sender;
*/
-(BOOL)handleEvent:(NSEvent*)event client:(id)sender{
    NSUInteger modifiers = [event modifierFlags];
    bool handled = NO;
    switch ([event type]) {
        case NSFlagsChanged:
            // FIXME: a dirty workaround for chrome sending duplicated NSFlagsChanged event
            if (_lastEventTypes[1] == NSFlagsChanged && _lastModifiers[1] == modifiers){
                return YES;
            }
            
            if (modifiers == 0
                &&_lastEventTypes[1] == NSFlagsChanged
                && _lastModifiers[1] == NSShiftKeyMask
                &&!(_lastModifiers[0] & NSShiftKeyMask)){
                defaultEnglishMode = !defaultEnglishMode;
                if(defaultEnglishMode){
                    
                    NSString* bufferedText = [self originalBuffer];
                    if ( bufferedText && [bufferedText length] > 0 ) {
                        [self cancelComposition];
                        NSLog(@"call commitComposition 00,bufferedText:%@",bufferedText);
                        [self commitComposition:sender];
                    }
                }
            }
            break;
        case NSKeyDown:
            if (defaultEnglishMode) {
                break;
            }
            handled = [self onKeyEvent:event client:sender];
            break;
        default:
            break;
    }
    
    _lastModifiers [0] = _lastModifiers[1];
    _lastEventTypes[0] = _lastEventTypes[1];
    _lastModifiers [1] = modifiers;
    _lastEventTypes[1] = [event type];
    
    return handled;
}

-(BOOL)onKeyEvent:(NSEvent*)event client:(id)sender{
    _currentClient = sender;
    NSUInteger modifiers = [event modifierFlags];
    NSInteger keyCode = [event keyCode];
    NSString* string = [event characters];
    
    if ([self shouldIgnoreKey:keyCode modifiers:modifiers]){
        [self reset];
        return NO;
    }
    
    if(keyCode == KEY_DELETE){
        NSString* bufferedText = [self originalBuffer];
        
        if ( bufferedText && [bufferedText length] > 0 ) {
            return [self deleteBackward:sender];
        }
        return NO;
    }
    
    NSString* bufferedText = [self originalBuffer];
    
    if(keyCode == KEY_RETURN){
        if ( [bufferedText length] > 0 ) {
            if(_is_cmd_mode && [self isPasswordMode: bufferedText] ){
                [self commitPassword: bufferedText client: sender];
                return YES;
            }
            [self commitComposition:sender];
            return YES;
        }
        return NO;
    }
    
    if(keyCode == KEY_ESC){
        if ( bufferedText && [bufferedText length] > 0 ) {
            [self cancelComposition];
            [self commitComposition:sender];
            
            return YES;
        }
        return NO;
    }
    
    NSLog(@"bufferedText:%@,string:%@,%ld,boolean:%@",bufferedText,string, bufferedText.length,[bufferedText length] == 0  && [string  isEqualToString: @":"] ? @"YES" : @"NO");
    
    
    if ( [bufferedText length] == 0  && [string  isEqualToString: @":"]) {
        NSLog(@":::::::::::::::::::::::");
        [self appendToOriginalBuffer:string client:sender];
        NSLog(@"originalBuffer1:%@",[self originalBuffer]);
        return YES;
    }
    if ( [bufferedText isEqualToString: @":"] && [string isEqualToString: @"!"] ) {
        NSLog(@"!!!!!!!!!!!!!!!!!!");
        [self appendToOriginalBuffer:string client:sender];
        NSLog(@"originalBuffer2:%@",[self originalBuffer]);
        return YES;
    }
    if ( [bufferedText hasPrefix:@":!"] ) {
        _is_cmd_mode = YES;
        [self appendToOriginalBuffer:string client:sender];
        return YES;
    }
    
    char ch = [string characterAtIndex:0];
    if(ch >= 'a' && ch <= 'z'){
        [self originalBufferAppend:string client:sender];
        
        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
    }else{
        if ([bufferedText length] > 0 ) {
            [self originalBufferAppend:string client:sender];
            NSLog(@"call commitComposition 11,bufferedText:%@,string:%@",bufferedText,string);
            [self commitComposition: sender];
            return YES;
        }else{
            [sharedCandidates hide];
            NSLog(@"111111-NO");
            return NO;
        }
        
    }
    NSLog(@"22222-NO");
    return NO;
}

- (BOOL)deleteBackward:(id)sender{
    NSMutableString*		originalText = [self originalBuffer];
    
    if ( _insertionIndex > 0 ) {
        --_insertionIndex;
         
        NSString* convertedString = [originalText substringToIndex: originalText.length - 1];

        [self setComposedBuffer:convertedString];
        [self setOriginalBuffer:convertedString];
        
        [sender setMarkedText:convertedString
               selectionRange:NSMakeRange(_insertionIndex, 0)
             replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
        
        if(convertedString){
            [sharedCandidates updateCandidates];
            [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        }
        return YES;
    }
    return NO;
}

- (BOOL) shouldIgnoreKey:(NSInteger)keyCode modifiers:(NSUInteger)flags{
    return (keyCode == KEY_BACKSPACE
            || keyCode == KEY_MOVE_LEFT
            || keyCode == KEY_MOVE_RIGHT
            || keyCode == KEY_MOVE_DOWN
            || (flags & NSCommandKeyMask)
            || (flags & NSControlKeyMask)
            || (flags & NSAlternateKeyMask)
            || (flags & NSNumericPadKeyMask));
}

-(void)commitComposition:(id)sender{
//    NSTimer *timer = [[NSTimer scheduledTimerWithTimeInterval:0.050
//                                                       target:self
//                                                     selector:@selector(commit:)
//                                                     userInfo:nil
//                                                      repeats:NO] init];
//    [timer fire];
    
    [self commit];
}

-(void)commit{
    NSString*		text = [self composedBuffer];
    
    if ( text == nil || [text length] == 0 ) {
        text = [self originalBuffer];
    }
    
    NSLog(@"commitComposition,text:%@",text);
    [_currentClient insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    [self reset];
}

-(void)reset{
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    [sharedCandidates hide];
}

-(NSMutableString*)composedBuffer{
    if ( _composedBuffer == nil ) {
        _composedBuffer = [[NSMutableString alloc] init];
    }
    return _composedBuffer;
}

-(void)setComposedBuffer:(NSString*)string{
    NSMutableString*		buffer = [self composedBuffer];
    [buffer setString:string];
}

-(NSMutableString*)originalBuffer{
    if ( _originalBuffer == nil ) {
        _originalBuffer = [[NSMutableString alloc] init];
    }
    return _originalBuffer;
}

-(void)originalBufferAppend:(NSString*)string client:(id)sender{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
    _insertionIndex++;
    [sender setMarkedText:buffer selectionRange:NSMakeRange([buffer length], 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

-(void)appendToOriginalBuffer:(NSString*)string client:(id)sender{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
}

-(BOOL) isPasswordMode:(NSString*)bufferedText{
    return [bufferedText rangeOfString: @"zhima"].location != NSNotFound;
}

-(NSString*)getPassword:(id)sender{
    NSString* password = [passwordDict objectForKey: [sender bundleIdentifier]];
    return password;
}

-(void)setPassword:(NSString*)string client:(id)sender{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@":!\\s*zhima\\s*(.+)"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:NULL];
    [regex enumerateMatchesInString:string
                            options:0
                              range:NSMakeRange(0, [string length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                             
        NSString* password = [[string substringWithRange:[match rangeAtIndex:1]]
                            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                             
        [passwordDict setValue: password forKey: [sender bundleIdentifier]];
    }];
}

-(void)commitPassword:(NSString*)bufferedText client:(id)sender{
    NSString* password;
    if([bufferedText hasSuffix:@"zhima"]){
        password = [self getPassword:sender];
    }else{
        [self setPassword: bufferedText client: sender];
        password = [self getPassword:sender];
    }
    
    [sender insertText: password replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    [self reset];
}

-(void)setOriginalBuffer:(NSString*)string{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

-(void) :(id)sender{
    [sharedCandidates hide];
}

- (NSArray*)candidates:(id)sender{
    NSMutableString* buffer = [self originalBuffer];
    NSMutableArray* result = [[NSMutableArray alloc] init];
    
    if(buffer && buffer.length > 0){
        NSArray* filtered = [trie everyObjectForKeyWithPrefix:[NSString stringWithString: buffer]];
        
        if(filtered && filtered.count > 0){
            NSMutableArray* frequentWords = [NSMutableArray arrayWithArray:[self sortByFrequency:filtered]];
            if(frequentWords && frequentWords.count > 0){
                result = frequentWords;
            }else{
                result = [NSMutableArray arrayWithArray:filtered];
            }
        }else{
            result = [self getSuggestionOfSpellChecker:buffer];
        }
        
        if(result.count >= 100){
            result = [NSMutableArray arrayWithArray: [result subarrayWithRange:NSMakeRange(0, 99)]];
        }
        
        [result removeObject:buffer];
        [result insertObject:buffer atIndex:0];
    }
    
    return [NSArray arrayWithArray:result];
}

-(NSMutableArray*)getSuggestionOfSpellChecker:(NSString*)buffer{
    NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
    NSRange range = NSMakeRange(0, [buffer length]);
    NSMutableArray* suggestion = [NSMutableArray arrayWithArray:
                                  [checker guessesForWordRange:range
                                                      inString:buffer
                                                      language:@"en"
                                        inSpellDocumentWithTag:0]];
    
    return suggestion;
}

-(NSArray*)sortByFrequency:(NSArray*) filtered{
    NSArray *sorted = [filtered sortedArrayUsingComparator:^NSComparisonResult(id w1, id w2) {
        int n = [[wordsWithFrequency objectForKey: w1] intValue] - [[wordsWithFrequency objectForKey:w2] intValue];
        if (n > 0){
            return (NSComparisonResult)NSOrderedAscending;
        }
        if (n < 0){
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    return sorted;
}

- (void)candidateSelectionChanged:(NSAttributedString*)candidateString{
    [_currentClient setMarkedText:[candidateString string]
                   selectionRange:NSMakeRange(_insertionIndex, 0)
                 replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
    
    _insertionIndex = [candidateString length];
    
    [self showPhoneticSymbolOfWord:candidateString];
}

- (void)showPhoneticSymbolOfWord:(NSAttributedString*)candidateString{
    if(candidateString && candidateString.length > 3){
        @try {
            NSString *definition = (__bridge NSString *)DCSCopyTextDefinition(NULL,
                                            (__bridge CFStringRef)[candidateString string],
                                            CFRangeMake(0, [[candidateString string] length]));
            
            
            if(definition && definition.length > 0){
                NSArray* arr = [definition componentsSeparatedByString:@"|"];
                if([arr count] > 0){
                    NSString* phoneticSymbol = [NSString stringWithFormat:@"[ %@ ]",
                                                [definition componentsSeparatedByString:@"|"][1]];
                    [sharedCandidates showAnnotation: [[NSAttributedString alloc] initWithString: phoneticSymbol]];
                }
                
            }
        }
        @catch (NSException *exception) {
            NSLog(@"error when call showPhoneticSymbolOfWord %@", exception.reason);
        }
    }
}

- (void)candidateSelected:(NSAttributedString*)candidateString{
    [self setComposedBuffer:[candidateString string]];
    NSLog(@"call commitComposition,candidateString:%@",[candidateString string]);
    [self commitComposition:_currentClient];
}

@end