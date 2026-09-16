#import <Foundation/Foundation.h>

// Remembers the marked text last handed to a client, so an identical update can
// be skipped.
//
// One keystroke updates the client's marked text from several places (the
// buffer append, then the highlight sync) with the same content, and every
// update is a call across the input method boundary. This is the state that
// decides whether the next one is redundant.
//
// Pure logic: no AppKit and no client, so the skip rules are unit-testable.
// The client is compared by identity, and the record must be dropped whenever
// what the client shows can no longer be assumed to be what we sent - after a
// commit, a cancel, a reset or a client switch - otherwise a later composition
// that repeats the same string would be swallowed.
@interface MarkedTextState : NSObject

// YES when `client` is already showing exactly this string and selection.
- (BOOL)isCurrentForString:(NSString *)string selectionRange:(NSRange)selectionRange client:(id)client;

// Records that `string` and `selectionRange` were just sent to `client`.
- (void)recordString:(NSString *)string selectionRange:(NSRange)selectionRange client:(id)client;

// Drops the record, so the next update is always delivered.
- (void)forget;

@end
