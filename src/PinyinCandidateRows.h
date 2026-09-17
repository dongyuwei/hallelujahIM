#import <Foundation/Foundation.h>

// Row model for the pinyin candidate panel.
//
// Like the English panel, which always lists the typed buffer as its first
// candidate, the pinyin panel shows the raw (unconverted) input as row 0, so
// space, enter and 1 can commit exactly what was typed. Rime's candidates for
// the current page follow, one row down.
//
// Pure logic: no AppKit and no Rime session, so the row layout and the row
// indexing rules are unit-testable.
@interface PinyinCandidateRows : NSObject

// The rows to hand the candidate panel: `rawInput` first (when non-empty),
// then `rimeCandidates`. The raw input is never a Rime candidate, so no
// de-duplication is needed.
+ (NSArray<NSString *> *)rowsForRawInput:(NSString *)rawInput rimeCandidates:(NSArray<NSString *> *)rimeCandidates;

// YES when the panel row commits the raw input instead of a Rime candidate.
+ (BOOL)rowIsRawInput:(NSInteger)row;

// The Rime page index for a panel row. Only valid for rows that are not the
// raw-input row (check rowIsRawInput: first).
+ (NSInteger)rimeIndexForRow:(NSInteger)row;

@end
