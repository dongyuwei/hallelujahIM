#import "InputController.h"
#import "PJTernarySearchTree.h"
#import <AppKit/NSSpellChecker.h>
#import <CoreServices/CoreServices.h>

extern IMKCandidates*           sharedCandidates;
extern IMKCandidates*           subCandidates;
extern PJTernarySearchTree*     trie;
extern NSMutableDictionary*     wordsWithFrequency;
extern BOOL                     defaultEnglishMode;
extern NSDictionary*            translationes;
extern NSDictionary*            substitutions;

typedef NSInteger KeyCode;
static const KeyCode
KEY_DELETE = 51,
KEY_ESC = 53;

@implementation InputController

-(NSUInteger)recognizedEvents:(id)sender{
    return NSKeyDownMask | NSFlagsChangedMask;
}

-(BOOL)handleEvent:(NSEvent*)event client:(id)sender{
    NSUInteger modifiers = [event modifierFlags];
    bool handled = NO;
    switch ([event type]) {
        case NSFlagsChanged:
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
            if (defaultEnglishMode){
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
    NSInteger keyCode = [event keyCode];
    NSString* string = [event characters];
    
    if(keyCode == KEY_DELETE){
        NSString* bufferedText = [self originalBuffer];
        
        if ( bufferedText && [bufferedText length] > 0 ) {
            return [self deleteBackward:sender];
        }
        
        return NO;
    }
    
    NSString* bufferedText = [self originalBuffer];
    
    if(keyCode == KEY_ESC){
        if ( bufferedText && [bufferedText length] > 0 ) {
            [self cancelComposition];
            [self commitComposition:sender];
            
            return YES;
        }
        return NO;
    }
    
    char ch = [string characterAtIndex:0];
    if( (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ){
        [self originalBufferAppend:string client:sender];
        
        [sharedCandidates updateCandidates];
        [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        return YES;
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
        
        if(convertedString && convertedString.length > 0){
            [sharedCandidates updateCandidates];
            [sharedCandidates show:kIMKLocateCandidatesBelowHint];
        }else{
            [self reset];
        }
        return YES;
    }
    return NO;
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


-(void)setOriginalBuffer:(NSString*)string{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

- (NSArray*)candidates:(id)sender{
    NSString* buffer = [[self originalBuffer] lowercaseString];
    NSMutableArray* result = [[NSMutableArray alloc] init];
    
    if(buffer && buffer.length > 0){
        if(substitutions && substitutions[buffer]){
            result = [NSMutableArray arrayWithArray: @[substitutions[buffer]]];
        }
        else if([buffer hasPrefix:@"gs"] && [buffer length] > 2){//get Google Suggestion if inputed word has prefix `gs`
            result = [NSMutableArray arrayWithArray: [self getGoogleSuggestion: [buffer substringFromIndex:2]]];
        }else if([buffer hasPrefix:@"pinyin"] && [buffer length] > 6){
            result = [NSMutableArray arrayWithArray: [self getPinyinCandidates:[buffer substringFromIndex:6]]];
        }else{
            NSArray* filtered = [trie retrievePrefix:[NSString stringWithString: buffer] countLimit: 0];
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
    
    [self showSubCandidates: candidateString];
}

-(void)showSubCandidates:(NSAttributedString*)candidateString{
    NSInteger candidateIdentifier = [sharedCandidates selectedCandidate];
    NSInteger subCandidateStringIdentifier = [sharedCandidates candidateStringIdentifier: candidateString];

    if (candidateIdentifier == subCandidateStringIdentifier) {
        NSArray* subList = [self getSubCandidates: candidateString];
        if(subList && subList.count > 0){
            NSString* phoneticSymbol = [self getPhoneticSymbolOfWord: candidateString];
            if([phoneticSymbol length] > 0){
                NSArray* list = @[phoneticSymbol];
                [subCandidates setCandidateData: [list arrayByAddingObjectsFromArray:subList]];
            }else{
                [subCandidates setCandidateData: subList];
            }
            
            NSRect currentFrame = [sharedCandidates candidateFrame];
            NSPoint windowInsertionPoint = NSMakePoint(NSMaxX(currentFrame), NSMaxY(currentFrame));
            [subCandidates setCandidateFrameTopLeft:windowInsertionPoint];
            
            
            [sharedCandidates attachChild:subCandidates toCandidate:(NSInteger)candidateIdentifier type:kIMKSubList];
            [sharedCandidates showChild];
        }else{
            [subCandidates hide];
        }
    }else{
        [subCandidates hide];
    }
}

-(NSArray*)getSubCandidates: (NSAttributedString*)candidateString{
    return translationes[[[candidateString string] lowercaseString]];
}

-(NSString*) getPhoneticSymbolOfWord:(NSAttributedString*)candidateString{
    NSString* phoneticSymbol = nil;
    if(candidateString && candidateString.length > 3){
        @try {
            NSString *definition = (__bridge NSString *)DCSCopyTextDefinition(NULL,
                                            (__bridge CFStringRef)[candidateString string],
                                            CFRangeMake(0, [[candidateString string] length]));
            
            
            if(definition && definition.length > 0){
                NSArray* arr = [definition componentsSeparatedByString:@"|"];
                if([arr count] > 0){
                    phoneticSymbol = [NSString stringWithFormat:@"[ %@ ]", arr[1]];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"error when call showPhoneticSymbolOfWord %@", exception.reason);
        }
    }
    
    return phoneticSymbol;
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

-(NSArray*) getGoogleSuggestion: (NSString*)word{
    NSString* query = [NSString stringWithFormat: @"http://google.com/complete/search?output=firefox&hl=en&q=%@", word];
    NSURL * url = [[NSURL alloc] initWithString: query];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:3];
    
    NSURLResponse *response;
    NSError *error;
    
    NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];
    
    
    NSArray* result = @[];
    if(!error && data){
        NSArray* object = [NSJSONSerialization
                           JSONObjectWithData:data
                           options:0
                           error:&error];
        
        if(!error){
            result = object[1];
        }else{
            NSLog(@"getGoogleSuggestion Error: %@",error);
        }

    }else{
        NSLog(@"getGoogleSuggestion Error: %@",error);
    }
    
    return result;
}

-(NSArray*) getPinyinCandidates: (NSString*)word{
    NSString* query = [NSString stringWithFormat: @"http://olime.baidu.com/py?input=%@&inputtype=py&bg=0&ed=20&result=hanzi&resultcoding=unicode&ch_en=0&clientinfo=web&version=1", word];
    NSURL * url = [[NSURL alloc] initWithString: query];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:3];
    
    NSURLResponse *response;
    NSError *error;
    
    NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];
    
    
    NSArray* result = @[];
    if(!error && data){
        NSDictionary* object = [NSJSONSerialization
                                JSONObjectWithData:data
                                options:0
                                error:&error];
        
        if(!error){
            result = object[@"result"][0];
        }else{
            NSLog(@"getPinyinCandidates Error: %@",error);
        }
        
    }else{
        NSLog(@"getPinyinCandidates Error: %@",error);
    }
    
    if([result count] > 0){
        NSMutableArray* finalResult = [[NSMutableArray alloc] init];
        for(id item in result){
            [finalResult addObject: item[0]];
        }
        return [NSArray arrayWithArray:finalResult];
    }
    return result;}

@end
