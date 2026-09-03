#import "CandidatePanelState.h"

// Vertical window: 9 rows (matches the old page size).
static const NSInteger kVerticalVisibleRows = 9;
// Grid window: 5 rows of 5 columns before the window starts scrolling.
static const NSInteger kGridVisibleRows = 5;
static const NSInteger kGridColumns = 5;

@interface CandidatePanelState ()

@property(nonatomic, copy) NSArray<NSString *> *candidates;
@property(nonatomic) CandidatePanelLayout layout;
@property(nonatomic) NSInteger gridColumns;

@property(nonatomic) NSInteger activeIndex;
@property(nonatomic) NSInteger verticalTopVisibleLine;

@property(nonatomic) BOOL gridIsExpanded;
@property(nonatomic) NSInteger gridActiveRow;
@property(nonatomic) NSInteger gridActiveColumn;
@property(nonatomic) NSInteger gridVisibleRowOffset;

@end

@implementation CandidatePanelState

- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates layout:(CandidatePanelLayout)layout {
    self = [super init];
    if (self) {
        _candidates = [candidates copy];
        _layout = layout;
        _gridColumns = kGridColumns;
    }
    return self;
}

- (NSInteger)verticalVisibleRows {
    return kVerticalVisibleRows;
}

- (NSInteger)gridVisibleRows {
    return kGridVisibleRows;
}

#pragma mark - Vertical

- (NSInteger)selectedIndex {
    if (self.layout == CandidatePanelLayoutGrid) {
        return self.gridActiveRow * self.gridColumns + self.gridActiveColumn;
    }
    return self.activeIndex;
}

- (void)moveDown {
    if (self.candidates.count == 0) {
        return;
    }
    if (self.activeIndex < (NSInteger)self.candidates.count - 1) {
        self.activeIndex++;
        if (self.activeIndex >= self.verticalTopVisibleLine + self.verticalVisibleRows) {
            self.verticalTopVisibleLine = self.activeIndex - self.verticalVisibleRows + 1;
        }
    }
}

- (void)moveUp {
    if (self.activeIndex > 0) {
        self.activeIndex--;
    }
    if (self.activeIndex < self.verticalTopVisibleLine) {
        self.verticalTopVisibleLine = self.activeIndex;
    }
}

#pragma mark - Grid

- (NSInteger)columnCountForRow:(NSInteger)row {
    NSInteger remaining = (NSInteger)self.candidates.count - row * self.gridColumns;
    return MAX(0, MIN(self.gridColumns, remaining));
}

- (NSInteger)gridTotalRows {
    if (self.candidates.count == 0) {
        return 0;
    }
    return ((NSInteger)self.candidates.count + self.gridColumns - 1) / self.gridColumns;
}

- (NSInteger)gridRenderedRowCount {
    if (!self.gridIsExpanded) {
        return 1;
    }
    return MIN(self.gridTotalRows, self.gridVisibleRows);
}

- (void)gridMoveDown {
    if (self.candidates.count == 0) {
        return;
    }
    if (!self.gridIsExpanded) {
        self.gridIsExpanded = YES;
        return;
    }
    if (self.gridActiveRow < self.gridTotalRows - 1) {
        self.gridActiveRow++;
    }
    [self clampGridColumn];
    [self clampGridVisibleWindow];
}

- (void)gridMoveUp {
    if (!self.gridIsExpanded || self.candidates.count == 0) {
        return;
    }
    if (self.gridActiveRow == 0) {
        self.gridIsExpanded = NO;
        self.gridVisibleRowOffset = 0;
        return;
    }
    self.gridActiveRow--;
    [self clampGridColumn];
    [self clampGridVisibleWindow];
}

- (void)gridMoveRight {
    NSInteger cols = [self columnCountForRow:self.gridActiveRow];
    if (cols == 0) {
        return;
    }
    self.gridActiveColumn = (self.gridActiveColumn + 1) % cols;
}

- (void)gridMoveLeft {
    NSInteger cols = [self columnCountForRow:self.gridActiveRow];
    if (cols == 0) {
        return;
    }
    self.gridActiveColumn = (self.gridActiveColumn - 1 + cols) % cols;
}

- (void)clampGridColumn {
    NSInteger cols = [self columnCountForRow:self.gridActiveRow];
    self.gridActiveColumn = MAX(0, MIN(self.gridActiveColumn, cols - 1));
}

- (NSInteger)indexForDigit:(NSInteger)digit {
    if (digit < 1 || digit > 9) {
        return NSNotFound;
    }
    if (self.layout == CandidatePanelLayoutGrid) {
        if (digit - 1 >= [self columnCountForRow:self.gridActiveRow]) {
            return NSNotFound;
        }
        return self.gridActiveRow * self.gridColumns + (digit - 1);
    }
    NSInteger index = self.verticalTopVisibleLine + (digit - 1);
    return index < (NSInteger)self.candidates.count ? index : NSNotFound;
}

- (void)clampGridVisibleWindow {
    if (self.gridActiveRow < self.gridVisibleRowOffset) {
        self.gridVisibleRowOffset = self.gridActiveRow;
    } else if (self.gridActiveRow >= self.gridVisibleRowOffset + self.gridVisibleRows) {
        self.gridVisibleRowOffset = self.gridActiveRow - self.gridVisibleRows + 1;
    }
    self.gridVisibleRowOffset = MAX(0, self.gridVisibleRowOffset);
}

@end
