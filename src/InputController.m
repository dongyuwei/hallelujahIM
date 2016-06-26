#import "InputController.h"
#import "FMDatabase.h"

extern IMKCandidates*           sharedCandidates;
extern FMDatabase*              db;
extern BOOL                     defaultEnglishMode;

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
    NSArray* result = @[];
    
    if(buffer && buffer.length > 0){
        result = [self querySqliteDb: buffer];
    }
    
    return result;
}

-(NSArray*)querySqliteDb:(NSString*)key{
    NSMutableArray* filtered = [[NSMutableArray alloc] init];

    NSString* sql = [NSString stringWithFormat: @"select value from mapping  where key like '%@%@' limit 50", key, @"%"];
    FMResultSet *rs = [db executeQuery: sql];
    while ([rs next]) {
        [filtered addObject: [rs stringForColumn:@"value"]];
    }
 
    return [NSMutableArray arrayWithArray: filtered];;
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

@end