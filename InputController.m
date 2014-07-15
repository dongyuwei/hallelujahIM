#import "InputController.h"
#import "NDTrie.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

extern IMKCandidates *sharedCandidates;
extern NDMutableTrie*  trie;
extern NSDictionary* wordsWithFrequency;
extern BOOL defaultEnglishMode;

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
    //tail -f /var/log/system.log
    NSLog(@"event:%@",event);
    
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
                &&!(_lastModifiers[0] & NSShiftKeyMask)){
                defaultEnglishMode = !defaultEnglishMode;
                if(defaultEnglishMode){
                    NSLog(@"Switched to default English mode!");
                    
                    NSString* bufferedText = [self originalBuffer];
                    if ( bufferedText && [bufferedText length] > 0 ) {
                        [self cancelComposition];
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
        defaults:
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
        if(!bufferedText || [bufferedText length] <= 0){
            return NO;
        }
        
        [self commitComposition:sender];
        return YES;
    }
    
    if(keyCode == KEY_ESC){
        if(!bufferedText || [bufferedText length] <= 0){
            return NO;
        }
        
        [self cancelComposition];
        [self commitComposition:sender];
        return YES;
    }
    
    char ch = [string characterAtIndex:0];
    if(ch >= 'a' && ch <= 'z'){
        [self originalBufferAppend:string client:sender];
        
        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
    }else{
        if(!bufferedText || [bufferedText length] <= 0){
            [sharedCandidates hide];
            return NO;
        }
        
        [self originalBufferAppend:string client:sender];
        [self commitComposition: sender];
        return YES;
    }
    
    return NO;
}

// If backspace is entered remove the preceding character and update the marked text.
- (BOOL)deleteBackward:(id)sender{
    NSMutableString*		originalText = [self originalBuffer];
    
    NSLog(@"deleteBackward originalText:%@,_insertionIndex:%ld", originalText,_insertionIndex);
    
    if (_insertionIndex <= 0) {
        return NO;
    }
    
    --_insertionIndex;
    
    NSString* convertedString = [originalText substringToIndex: originalText.length - 1];
    NSLog(@"deleteBackward, convertedString is :%@",convertedString);
    
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
    
    NSLog(@"commitComposition: %@",text);
    if (_candidateSelected){
        text = [text stringByAppendingString:@" "];
    }
    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    [self reset];
}

-(void)reset{
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    [sharedCandidates hide];
    _candidateSelected = NO;
}

// Return the composed buffer.  If it is NIL create it.
-(NSMutableString*)composedBuffer{
    if ( _composedBuffer == nil ) {
        _composedBuffer = [[NSMutableString alloc] init];
    }
    return _composedBuffer;
}

// Change the composed buffer.
-(void)setComposedBuffer:(NSString*)string{
    NSMutableString*		buffer = [self composedBuffer];
    [buffer setString:string];
}


// Get the original buffer.
-(NSMutableString*)originalBuffer{
    if ( _originalBuffer == nil ) {
        _originalBuffer = [[NSMutableString alloc] init];
    }
    return _originalBuffer;
}

// Add newly input text to the original buffer.
-(void)originalBufferAppend:(NSString*)string client:(id)sender{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
    _insertionIndex++;
    [sender setMarkedText:buffer selectionRange:NSMakeRange([buffer length], 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

// Change the original buffer.
-(void)setOriginalBuffer:(NSString*)string{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

- (void) activateServer:(id)client{
    NSLog(@"him activateServer");
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
    NSLog(@"candidateSelectionChanged, %@", [candidateString string]);
    [_currentClient setMarkedText:[candidateString string]
                   selectionRange:NSMakeRange(_insertionIndex, 0)
                 replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
    
    _insertionIndex = [candidateString length];
    
    [self showPhoneticSymbolOfWord:candidateString];
}

- (void)showPhoneticSymbolOfWord:(NSAttributedString*)candidateString{
    if(!candidateString || candidateString.length <= 3){
        return;
    }
    
    @try {
        NSString *definition = (NSString *)DCSCopyTextDefinition(NULL,
                                                                 (__bridge CFStringRef)[candidateString string],
                                                                 CFRangeMake(0, [[candidateString string] length]));
        
        if(definition && definition.length > 0){
            //                NSLog(@"definition of %@ is %@",[candidateString string], definition);
            
            NSArray* arr = [definition componentsSeparatedByString:@"|"];
            if([arr count] > 0){
                NSString* phoneticSymbol = [NSString stringWithFormat:@"[ %@ ]",
                                            [definition componentsSeparatedByString:@"|"][1]];
                [sharedCandidates showAnnotation: [[NSAttributedString alloc] initWithString: phoneticSymbol]];
            }
            
        }
    }
    @catch (NSException *exception) {
        NSLog(@"error when call showDefinitionOfWord %@", exception.reason);
    }

}

/*!
 @method
 @abstract   Called when a new candidate has been finally selected.
 @discussion The candidate parameter is the users final choice from the candidate window. The candidate window will have been closed before this method is called.
 */
- (void)candidateSelected:(NSAttributedString*)candidateString{
    _candidateSelected = YES;
    [self setComposedBuffer:[candidateString string]];
    [self commitComposition:_currentClient];
    
    NSLog(@"candidateSelected, %@", candidateString);
}

-(void)dealloc{
    [_composedBuffer release];
    [_originalBuffer release];
    [super dealloc];
}

@end