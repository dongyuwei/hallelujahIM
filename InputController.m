#import "InputController.h"
#import "NDTrie.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

extern IMKCandidates *sharedCandidates;
extern NDMutableTrie*  trie;
extern NSDictionary* wordsWithFrequency;


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


-(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender{
    //tail -f /var/log/system.log
    NSLog(@"text:%@, keycode:%ld, flags:%lu, bundleIdentifier: %@",
          string, (long)keyCode,(unsigned long)flags, [sender bundleIdentifier]);
    
    _currentClient = sender;
    
    if ([self shouldIgnoreKey:keyCode modifiers:flags]){
        [self reset];
        return NO;
    }
    
    if(keyCode == KEY_DELETE){
        NSString*		bufferedText = [self originalBuffer];
        
        if ( bufferedText && [bufferedText length] > 0 ) {
            return [self deleteBackward:sender];
        }
        return NO;
    }
    
    NSString*		bufferedText = [self originalBuffer];
    
    if(keyCode == KEY_RETURN){
        if ( bufferedText && [bufferedText length] > 0 ) {
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
    
    char ch = [string characterAtIndex:0];
    if(ch >= 'a' && ch <= 'z'){
        [self originalBufferAppend:string client:sender];

        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
    }else{
        if ( bufferedText && [bufferedText length] > 0 ) {
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

// If backspace is entered remove the preceding character and update the marked text.
- (BOOL)deleteBackward:(id)sender
{
    NSMutableString*		originalText = [self originalBuffer];
    
    NSLog(@"deleteBackward originalText:%@,_insertionIndex:%ld", originalText,_insertionIndex);
    
    if ( _insertionIndex > 0 ) {
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

-(void)commitComposition:(id)sender
{
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
-(NSMutableString*)composedBuffer;
{
    if ( _composedBuffer == nil ) {
        _composedBuffer = [[NSMutableString alloc] init];
    }
    return _composedBuffer;
}

// Change the composed buffer.
-(void)setComposedBuffer:(NSString*)string
{
    NSMutableString*		buffer = [self composedBuffer];
    [buffer setString:string];
}


// Get the original buffer.
-(NSMutableString*)originalBuffer
{
    if ( _originalBuffer == nil ) {
        _originalBuffer = [[NSMutableString alloc] init];
    }
    return _originalBuffer;
}

// Add newly input text to the original buffer.
-(void)originalBufferAppend:(NSString*)string client:(id)sender
{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
    _insertionIndex++;
    [sender setMarkedText:buffer selectionRange:NSMakeRange(0, [buffer length]) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

// Change the original buffer.
-(void)setOriginalBuffer:(NSString*)string
{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

- (void) activateServer:(id)client{
    NSLog(@"him activateServer");
}

-(void) :(id)sender {
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
    [_currentClient setMarkedText:[candidateString string] selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
    _insertionIndex = [candidateString length];
    
//    [self showDefinitionOfWord:candidateString];
}

- (void)showDefinitionOfWord:(NSAttributedString*)candidateString{
    if(candidateString && candidateString.length >= 3){
        @try {
            NSAttributedString *definition = (NSAttributedString *)DCSCopyTextDefinition(NULL,
                                                                                         (__bridge CFStringRef)[candidateString string], CFRangeMake(0, [[candidateString string] length]));
            
            NSLog(@"definition of %@ is %@",[candidateString string], definition);
            
            if(definition && definition.length > 0){
                NSString * defi = [definition string];
                NSRange range = [defi rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
                defi = [defi stringByReplacingCharactersInRange:range withString:@""];
                
                [sharedCandidates showAnnotation: [defi substringWithRange:NSMakeRange(0, 17)]];
            }else{
                [sharedCandidates showAnnotation: candidateString];
            }
            
        }
        @catch (NSException *exception) {
            NSLog(@"error when call showDefinitionOfWord %@", exception.reason);
        }
    }
}

/*!
 @method
 @abstract   Called when a new candidate has been finally selected.
 @discussion The candidate parameter is the users final choice from the candidate window. The candidate window will have been closed before this method is called.
 */
- (void)candidateSelected:(NSAttributedString*)candidateString
{
    _candidateSelected = YES;
    [self setComposedBuffer:[candidateString string]];
    [self commitComposition:_currentClient];
    
    NSLog(@"candidateSelected, %@", candidateString);
}

- (NSArray*) getBaiduDictSuggestion: (NSString*)word{
    NSArray* result = @[];
    
    @try {
        NSString* query = [NSString stringWithFormat: @"http://nssug.baidu.com/su?prod=recon_dict&wd=%@", word];
        NSURL * url = [[NSURL alloc] initWithString: query];
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                    cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                timeoutInterval:30];
        
        NSURLResponse *response;
        NSError *error;
        
        NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest
                                             returningResponse:&response
                                                         error:&error];
        if(error){
            NSLog(@"getBaiduDictSuggestion Error: %@, the word prefix is:%@",error, word);
            return result;
        }
        
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *chunks = [str componentsSeparatedByString: @"s:"];
        if(chunks && chunks.count > 1){
            NSArray *chunks2 = [chunks[1] componentsSeparatedByString: @"});"];
            
            if(chunks2 && chunks2.count != 0){
                NSData *data2 = [chunks2[0] dataUsingEncoding:NSUTF8StringEncoding];
                
                result = [NSJSONSerialization
                          JSONObjectWithData:data2
                          options:0
                          error:&error];
                
                NSLog(@"baidu dict suggestion is %@", result);
            }
        }
        
        if(error){
            NSLog(@"getBaiduDictSuggestion Error: %@, the word prefix is:%@",error, word);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"getBaiduDictSuggestion Error: %@, the word prefix is:%@",exception, word);
    }
    @finally {
        return result;
    }
}

- (NSArray*) getGoogleSuggestion: (NSString*)word{
    NSString* query = [NSString stringWithFormat: @"http://google.com/complete/search?output=firefox&hl=en&q=%@", word];
    NSURL * url = [[NSURL alloc] initWithString: query];

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:30];
    
    NSURLResponse *response;
    NSError *error;
    
    NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];
    
    
    NSArray* result = @[];
    NSArray* object = [NSJSONSerialization
                       JSONObjectWithData:data
                       options:0
                       error:&error];
    
    if(!error){
        result = object[1];
    }else{
        NSLog(@"getGoogleSuggestion Error: %@",error);
    }
    
    return result;
}

-(void)dealloc
{
    [_composedBuffer release];
    [_originalBuffer release];
    [super dealloc];
}

@end

