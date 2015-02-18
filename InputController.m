#import "InputController.h"
#import "NDTrie.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>
#import "PasswordManager.h"

extern IMKCandidates*           sharedCandidates;
extern IMKCandidates*           subCandidates;
extern NDMutableTrie*           trie;
extern NSMutableDictionary*     wordsWithFrequency;
extern BOOL                     defaultEnglishMode;
extern NSString*                dictName;


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
                && _lastEventTypes[1] == NSFlagsChanged
                && _lastModifiers[1] == NSShiftKeyMask
                && !(_lastModifiers[0] & NSShiftKeyMask)){
                
                defaultEnglishMode = !defaultEnglishMode;
                if(defaultEnglishMode){
                    
                    NSString* bufferedText = [self originalBuffer];
                    if ( bufferedText && [bufferedText length] > 0 ) {
                        [self cancelComposition];
                        [self commitComposition:sender];
                    }
                }
            }
            break;
        case NSKeyDown:
            if (defaultEnglishMode && ![[sender bundleIdentifier]  isEqual: @"com.cisco.Cisco-AnyConnect-Secure-Mobility-Client"]) {
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
    
    if ( [bufferedText length] == 0  && [string  isEqualToString: @":"]) {
        [self appendToOriginalBuffer:string client:sender];
        return YES;
    }
    if ( [bufferedText isEqualToString: @":"] && [string isEqualToString: @"!"] ) {
        [self appendToOriginalBuffer:string client:sender];
        return YES;
    }
    if ( [bufferedText hasPrefix:@":!"] ) {
        _is_cmd_mode = YES;
        [self appendToOriginalBuffer:string client:sender];
        return YES;
    }
    
    char ch = [string characterAtIndex:0];
    if( (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ){
        [self originalBufferAppend:string client:sender];
        
        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
    }else{
        if ([bufferedText length] > 0 ) {
            [self originalBufferAppend:string client:sender];
            [self commitComposition: sender];
            return YES;
        }else{
            [sharedCandidates hide];
            return NO;
        }
        
    }
    
    return NO;
}

- (BOOL)deleteBackward:(id)sender{
    NSMutableString*		originalText = [self originalBuffer];
    
    if ( _insertionIndex > 0 ) {
        --_insertionIndex;
         
        NSString* convertedString = [originalText substringToIndex: originalText.length - 1];

        [self setComposedBuffer:convertedString];
        [self setOriginalBuffer:convertedString];
        
        [self showPreeditString: convertedString];
        
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
    NSString*		text = [self composedBuffer];
    
    if ( text == nil || [text length] == 0 ) {
        text = [self originalBuffer];
    }
    
    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    int frequency = [[wordsWithFrequency objectForKey: text] intValue];
    if(!defaultEnglishMode){
        [wordsWithFrequency setValue: [NSNumber numberWithInt: frequency + 1] forKey: text];
    }
    
    [self reset];
}

-(void)reset{
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    [sharedCandidates hide];
    [subCandidates hide];
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

-(void)showPreeditString:(NSString*)string{
    NSDictionary*       attrs = [self markForStyle:kTSMHiliteSelectedRawText atRange:NSMakeRange(0, [string length])];
    NSAttributedString* attrString;
    
    NSString* originalBuff = [NSString stringWithString:[self originalBuffer]];
    if([[string lowercaseString] hasPrefix: [originalBuff lowercaseString]]){
        attrString = [[NSAttributedString alloc]initWithString:[NSString stringWithFormat: @"%@%@", originalBuff, [string substringFromIndex: originalBuff.length]] attributes: attrs];
    }else{
        attrString = [[NSAttributedString alloc] initWithString:string attributes:attrs];
    }
    
    [_currentClient setMarkedText:attrString
                   selectionRange:NSMakeRange(string.length, 0)
                 replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

-(void)originalBufferAppend:(NSString*)string client:(id)sender{
    NSMutableString* buffer = [self originalBuffer];
    [buffer appendString: string];
    _insertionIndex++;
    [self showPreeditString: buffer];
}

-(void)appendToOriginalBuffer:(NSString*)string client:(id)sender{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
}

-(BOOL) isPasswordMode:(NSString*)bufferedText{
    return [[bufferedText lowercaseString] rangeOfString: @"zhima"].location != NSNotFound;
}

-(void)commitPassword:(NSString*)bufferedText client:(id)sender{
    //keep the call sequences!
    [self setPasswordIfMatch:bufferedText client: sender];
    [self getPasswordIfMatch:bufferedText client: sender];
}

-(void)setPasswordIfMatch:(NSString*)bufferedText client:(id)sender{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@":!\\s*zhima\\s*(\\S+)\\s+(\\S+)"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:NULL];
    
    [regex enumerateMatchesInString:bufferedText
                            options:0
                              range:NSMakeRange(0, [bufferedText length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                             
                             if([match numberOfRanges] == 3){
                                 NSString* key = [ [bufferedText substringWithRange:[match rangeAtIndex:1]]
                                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                 NSString* password = [[bufferedText substringWithRange:[match rangeAtIndex:2]]
                                                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                 
                                 [PasswordManager storePasswordForServiceName: key
                                                              withAccountName: @"HallelujahIM"
                                                                  andPassword: password];
                                 
                                 [self _commitPassword:password client:sender];
                             }
                             
                             
                         }];
    
}

-(void)getPasswordIfMatch:(NSString*)bufferedText client:(id)sender{
    NSRegularExpression *extractKeyRegex = [NSRegularExpression
                                            regularExpressionWithPattern:@":!\\s*zhima\\s*(\\S+)"
                                            options:NSRegularExpressionCaseInsensitive
                                            error:NULL];
    
    [extractKeyRegex enumerateMatchesInString:bufferedText
                                      options:0
                                        range:NSMakeRange(0, [bufferedText length])
                                   usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                                       
                                       if([match numberOfRanges] == 2){
                                           NSString* key = [ [bufferedText substringWithRange:[match rangeAtIndex:1]]
                                                            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                           
                                           NSString *password = [PasswordManager getPasswordFromServiceName: key
                                                                                             forAccountName: @"HallelujahIM"];
                                           [self _commitPassword:password client:sender];
                                       }
                                   }];
    
    
}


-(void)_commitPassword:(NSString*)password client:(id)sender{
    if(![[sender bundleIdentifier] isEqual: @"com.google.Chrome"]){
       [sender insertText: password replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:password forType:NSStringPboardType];
    
    [self reset];
}

-(void)setOriginalBuffer:(NSString*)string{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

- (NSArray*)candidates:(id)sender{
    NSString* buffer = [[self originalBuffer] lowercaseString];
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
        
        if(result.count > 50){
            result = [NSMutableArray arrayWithArray: [result subarrayWithRange:NSMakeRange(0, 49)]];
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
    [self showPreeditString: [candidateString string]];
    
    _insertionIndex = [candidateString length];
    
//    [self showPhoneticSymbolOfWord:candidateString];
    [self showSubCandidates: candidateString];
    
}

-(void)showSubCandidates:(NSAttributedString*)candidateString{
    NSInteger candidateIdentifier = [sharedCandidates selectedCandidate];
    NSInteger subCandidateStringIdentifier = [sharedCandidates candidateStringIdentifier: candidateString];
    
    NSLog(@"%@: %ld==%ld", candidateString, candidateIdentifier, subCandidateStringIdentifier);

    if (candidateIdentifier == subCandidateStringIdentifier) {
        [subCandidates setCandidateData: [self getSubCandidates: candidateString]];
        
        NSRect currentFrame = [sharedCandidates candidateFrame];
        NSPoint windowInsertionPoint = NSMakePoint(NSMaxX(currentFrame), NSMaxY(currentFrame));
        [subCandidates setCandidateFrameTopLeft:windowInsertionPoint];
        
        
        [sharedCandidates attachChild:subCandidates toCandidate:(NSInteger)candidateIdentifier type:kIMKSubList];
        [sharedCandidates showChild];
        
        // Select the first choice
//        [subCandidates selectCandidate:[subCandidates candidateIdentifierAtLineNumber:0]];
        
//        candidateString = [subCandidates selectedCandidateString];
    }
    
}

-(NSArray*)getSubCandidates: (NSAttributedString*)candidateString{
    return @[@"foo", @"bar", @"foobar"];
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
                    NSString* phoneticSymbol = [NSString stringWithFormat:@"[ %@ ]", arr[1]];
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
    NSString* originalBuff = [NSString stringWithString:[self originalBuffer]];
    NSString* composed = [candidateString string];
    if([composed hasPrefix: [originalBuff lowercaseString]]){
        [self setComposedBuffer: [NSString stringWithFormat: @"%@%@", originalBuff, [composed substringFromIndex: originalBuff.length]]];
    }else{
        [self setComposedBuffer:composed];
    }
    [self commitComposition:_currentClient];
}

//when annotation clicked, speak the word.
- (void)annotationSelected:(NSAttributedString*)annotationString forCandidate:(NSAttributedString*)candidateString{
    NSSpeechSynthesizer *synth = [[NSSpeechSynthesizer alloc] initWithVoice:@"com.apple.speech.synthesis.voice.Alex"];
    [synth startSpeakingString:[candidateString string]];
}

- (void)deactivateServer:(id)sender{
//    performence!!
//    [self updateDictionary];
}

-(void)updateDictionary{
    NSString* path = [[NSBundle mainBundle] pathForResource:dictName ofType:@"json"];
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    [outputStream open];
    [NSJSONSerialization writeJSONObject:wordsWithFrequency
                                toStream:outputStream
                                 options:nil
                                   error:nil];
    [outputStream close];
}

@end