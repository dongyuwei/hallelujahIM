#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CandidatePanelLayout) {
    CandidatePanelLayoutVertical = 0,
    CandidatePanelLayoutGrid = 1,
};

// Pure navigation state for the candidate panel: no AppKit, fully testable.
//
// Vertical layout: a flat list; `activeIndex` is the highlighted row and
// `verticalTopVisibleLine` is the first row of the visible window.
//
// Grid layout: candidates are laid out `gridColumns` per row.
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
@property(nonatomic, readonly) CandidatePanelLayout layout;
@property(nonatomic, readonly) NSInteger gridColumns;         // grid: cells per row
@property(nonatomic, readonly) NSInteger verticalVisibleRows; // vertical: rows in window
@property(nonatomic, readonly) NSInteger gridVisibleRows;     // grid: rows in window

- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates layout:(CandidatePanelLayout)layout;

// Vertical navigation.
- (void)moveDown;
- (void)moveUp;

// Grid navigation.
- (void)gridMoveDown;  // expands when collapsed, otherwise moves down a row
- (void)gridMoveUp;    // collapses at row 0, otherwise moves up a row
- (void)gridMoveRight; // cycles within the active row
- (void)gridMoveLeft;

@property(nonatomic, readonly) NSInteger selectedIndex; // absolute index of the highlight, 0 when empty
@property(nonatomic, readonly) NSInteger verticalTopVisibleLine;
@property(nonatomic, readonly) BOOL gridIsExpanded;
@property(nonatomic, readonly) NSInteger gridActiveRow;
@property(nonatomic, readonly) NSInteger gridActiveColumn;
@property(nonatomic, readonly) NSInteger gridVisibleRowOffset;
@property(nonatomic, readonly) NSInteger gridTotalRows;
@property(nonatomic, readonly) NSInteger gridRenderedRowCount; // 1 when collapsed, else up to gridVisibleRows

@end
