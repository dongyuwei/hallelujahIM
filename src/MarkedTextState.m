#import "MarkedTextState.h"

@implementation MarkedTextState {
    // Weak: holding the client alive to answer "did we already send this?" is
    // not worth it, and a deallocated client is never equal to the next one.
    __weak id _client;
    NSString *_string;
    NSRange _selectionRange;
}

- (BOOL)isCurrentForString:(NSString *)string selectionRange:(NSRange)selectionRange client:(id)client {
    return client != nil && client == _client && NSEqualRanges(_selectionRange, selectionRange) && [_string isEqualToString:string];
}

- (void)recordString:(NSString *)string selectionRange:(NSRange)selectionRange client:(id)client {
    _client = client;
    _string = [string copy];
    _selectionRange = selectionRange;
}

- (void)forget {
    _client = nil;
    _string = nil;
    _selectionRange = NSMakeRange(NSNotFound, 0);
}

@end
