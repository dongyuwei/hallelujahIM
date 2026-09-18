#import <Foundation/Foundation.h>

// Row model for the pinyin candidate panel.
//
// Like the English panel, which always lists the typed buffer among its first
// candidates, the pinyin panel reserves one row for the raw (unconverted)
// input, so the digit matching its position can commit exactly what was typed
// (space and enter commit the highlighted row, which starts at row 0). Where
// that row sits - 1st through 5th candidate - is the user's choice; the
// default is the 2nd, keeping space on the best Chinese candidate.
//
// The rows are Rime's candidates for the current page with the raw input
// spliced in at the configured position. Rows above the raw-input row keep
// their Rime page index; rows below it shift by one.
//
// Pure logic: no AppKit and no Rime session, so the row layout and the row
// indexing rules are unit-testable.
@interface PinyinCandidateRows : NSObject

// The highest candidate position the raw input can be configured to.
@property(nonatomic, class, readonly) NSInteger maxPosition;

// The lowest candidate position the raw input can be configured to.
@property(nonatomic, class, readonly) NSInteger minPosition;

// Clamps a preference value into the valid position range.
+ (NSInteger)clampedPosition:(NSInteger)position;

// Builds the rows for one page. `preferredPosition` is the 1-based candidate
// position for the raw input (clamped to minPosition...maxPosition); when the
// page has fewer candidates than that, the raw input lands at the end. An
// empty raw input yields no raw-input row at all.
- (instancetype)initWithRawInput:(NSString *)rawInput
                  rimeCandidates:(NSArray<NSString *> *)rimeCandidates
               preferredPosition:(NSInteger)preferredPosition NS_DESIGNATED_INITIALIZER;

// The rows to hand the candidate panel.
@property(nonatomic, readonly) NSArray<NSString *> *rows;

// The row that commits the raw input; NSNotFound when there is none.
@property(nonatomic, readonly) NSInteger rawInputRow;

// YES when the panel row commits the raw input instead of a Rime candidate.
- (BOOL)rowIsRawInput:(NSInteger)row;

// The Rime page index for a panel row. Only valid for rows that are not the
// raw-input row (check rowIsRawInput: first).
- (NSInteger)rimeIndexForRow:(NSInteger)row;

@end
