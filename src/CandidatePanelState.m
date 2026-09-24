#import "CandidatePanelState.h"

// Grid window: 5 rows before the window starts scrolling.
static const NSInteger kGridVisibleRows = 5;

@interface CandidatePanelState ()

@property(nonatomic, copy) NSArray<NSString *> *candidates;
@property(nonatomic) NSInteger gridColumns;

@property(nonatomic) NSInteger gridActiveRow;
@property(nonatomic) NSInteger gridActiveColumn;
@property(nonatomic) BOOL gridIsExpanded;
@property(nonatomic) NSInteger gridVisibleRowOffset;

@end

@implementation CandidatePanelState

- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates {
    return [self initWithCandidates:candidates columns:kCandidateGridDefaultColumns];
}

- (instancetype)initWithCandidates:(NSArray<NSString *> *)candidates columns:(NSInteger)columns {
    self = [super init];
    if (self) {
        _candidates = [candidates copy];
        _gridColumns = MAX(kCandidateGridMinColumns, MIN(columns, kCandidateGridMaxColumns));
    }
    return self;
}

- (NSInteger)gridVisibleRows {
    return kGridVisibleRows;
}

- (NSInteger)selectedIndex {
    return self.gridActiveRow * self.gridColumns + self.gridActiveColumn;
}

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
    if (digit - 1 >= [self columnCountForRow:self.gridActiveRow]) {
        return NSNotFound;
    }
    return self.gridActiveRow * self.gridColumns + (digit - 1);
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
