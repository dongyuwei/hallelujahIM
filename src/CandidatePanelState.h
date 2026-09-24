#import <Foundation/Foundation.h>

// Grid columns are clamped to this range: digits 1-9 are the selection keys, so
// a row wider than 9 columns would hold cells that no key can reach, and below 5
// there is no reason to have a grid at all.
enum {
    kCandidateGridMinColumns = 5,
    kCandidateGridMaxColumns = 9,
    kCandidateGridDefaultColumns = 5,
};

// Pure navigation state for the grid candidate panel: no AppKit, fully
// testable.
//
// Candidates are laid out `gridColumns` per row.
// - Left/Right cycle `gridActiveColumn` within the active row (wraps).
// - Down expands the grid on the first press (without moving); on
//   subsequent presses it moves the active row down one, scrolling the
//   visible window when the row leaves it.
// - Up moves the active row up; from row 0 while expanded it collapses.
//
// Every update resets to row 0 / column 0 (the input method clears the
// highlight whenever candidates refresh), navigation happens between updates.
@interface CandidatePanelState : NSObject

@property(nonatomic, readonly) NSArray<NSString *> *candidates;
@property(nonatomic, readonly) NSInteger gridColumns;     // grid: cells per row, 5-9
@property(nonatomic, readonly) NSInteger gridVisibleRows; // grid: rows in window

- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates;

// Designated initializer. `columns` is clamped to
// kCandidateGridMinColumns...kCandidateGridMaxColumns.
- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates columns:(NSInteger)columns;

// Grid navigation.
- (void)gridMoveDown;  // expands when collapsed, otherwise moves down a row
- (void)gridMoveUp;    // collapses at row 0, otherwise moves up a row
- (void)gridMoveRight; // cycles within the active row
- (void)gridMoveLeft;

// 1-based selection key: the column within the active grid row. NSNotFound
// when no candidate is reachable at that position.
- (NSInteger)indexForDigit:(NSInteger)digit;

@property(nonatomic, readonly) NSInteger selectedIndex; // absolute index of the highlight, 0 when empty
@property(nonatomic, readonly) BOOL gridIsExpanded;
@property(nonatomic, readonly) NSInteger gridActiveRow;
@property(nonatomic, readonly) NSInteger gridActiveColumn;
@property(nonatomic, readonly) NSInteger gridVisibleRowOffset;
@property(nonatomic, readonly) NSInteger gridTotalRows;
@property(nonatomic, readonly) NSInteger gridRenderedRowCount; // 1 when collapsed, else up to gridVisibleRows

@end
