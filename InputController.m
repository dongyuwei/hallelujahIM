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

-(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender{
//    NSLog(@"text:%@, keycode:%ld, flags:%lu, bundleIdentifier: %@",
//          string, (long)keyCode,(unsigned long)flags, [sender bundleIdentifier]);
    
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
            [_annotationWin hideWindow];
            return YES;
        }
        return NO;
    }
    
    if(keyCode == KEY_ESC){
        if ( bufferedText && [bufferedText length] > 0 ) {
            [self cancelComposition];
            [self commitComposition:sender];
            [_annotationWin hideWindow];

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
            [_annotationWin hideWindow];
            return NO;
        }
        
    }
    
    return NO;
}

- (void)activateServer:(id)sender {
    if (_annotationWin == nil){
        _annotationWin = [AnnotationWinController sharedController];
    }
}

- (void)deactivateServer:(id)sender {
    [_annotationWin hideWindow];
}

- (BOOL)deleteBackward:(id)sender{
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
    return ((flags & NSCommandKeyMask)
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
//    if (_candidateSelected){
//        text = [text stringByAppendingString:@" "];
//    }
    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    [self reset];
}

-(void)reset{
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    [sharedCandidates hide];
    _candidateSelected = NO;
    
    [_annotationWin hideWindow];
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
    [sender setMarkedText:buffer selectionRange:NSMakeRange(0, [buffer length]) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

-(void)setOriginalBuffer:(NSString*)string{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
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
    
    [self showDefinitionOfWord:candidateString];
}

- (void)showDefinitionOfWord:(NSAttributedString*)candidateString{
    if(candidateString && candidateString.length > 3){
        @try {
            NSString *definition = (NSString *)DCSCopyTextDefinition(NULL,
                                            (__bridge CFStringRef)[candidateString string],
                                            CFRangeMake(0, [[candidateString string] length]));
            
            
            if(definition && definition.length > 0){
                NSRect currentFrame = [sharedCandidates candidateFrame];
                NSRect tempRect;
                [_currentClient attributesForCharacterIndex:0 lineHeightRectangle:&tempRect];
                NSPoint windowInsertionPoint = NSMakePoint(NSMinX(tempRect), NSMinY(tempRect));
                windowInsertionPoint.x = windowInsertionPoint.x + currentFrame.size.width;
                
                [_annotationWin setAnnotation: definition];
                [_annotationWin showWindow: windowInsertionPoint];
            } else {
                [_annotationWin hideWindow];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"error when call showDefinitionOfWord %@", exception.reason);
        }
    }
}

- (void)candidateSelected:(NSAttributedString*)candidateString{
    _candidateSelected = YES;
    [self setComposedBuffer:[candidateString string]];
    [self commitComposition:_currentClient];
    
    [_annotationWin hideWindow];
}

-(void)dealloc{
    [_composedBuffer release];
    [_originalBuffer release];
    [super dealloc];
}

@end
