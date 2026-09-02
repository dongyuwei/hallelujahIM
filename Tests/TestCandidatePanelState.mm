#import "CandidatePanelState.h"
#import <XCTest/XCTest.h>

@interface TestCandidatePanelState : XCTestCase
@end

@implementation TestCandidatePanelState

- (CandidatePanelState *)verticalWithCount:(NSInteger)count {
    NSMutableArray *c = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        [c addObject:[NSString stringWithFormat:@"w%ld", (long)i]];
    }
    return [[CandidatePanelState alloc] initWithCandidates:c layout:CandidatePanelLayoutVertical];
}

- (CandidatePanelState *)gridWithCount:(NSInteger)count {
    NSMutableArray *c = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        [c addObject:[NSString stringWithFormat:@"w%ld", (long)i]];
    }
    return [[CandidatePanelState alloc] initWithCandidates:c layout:CandidatePanelLayoutGrid];
}

#pragma mark - Vertical

- (void)testVerticalMoveDownClampsAtEnd {
    CandidatePanelState *s = [self verticalWithCount:3];
    [s moveDown];
    XCTAssertEqual(s.selectedIndex, 1);
    [s moveDown];
    XCTAssertEqual(s.selectedIndex, 2);
    [s moveDown]; // clamped
    XCTAssertEqual(s.selectedIndex, 2);
}

- (void)testVerticalMoveUpDoesNotGoBelowZero {
    CandidatePanelState *s = [self verticalWithCount:3];
    [s moveUp];
    XCTAssertEqual(s.selectedIndex, 0);
}

- (void)testVerticalWindowScrollsAfterNineRows {
    CandidatePanelState *s = [self verticalWithCount:20];
    for (NSInteger i = 0; i < 10; i++) {
        [s moveDown];
    }
    XCTAssertEqual(s.selectedIndex, 10);
    XCTAssertEqual(s.verticalTopVisibleLine, 2); // keep highlight inside the 9-row window
    for (NSInteger i = 0; i < 5; i++) {
        [s moveUp];
    }
    XCTAssertEqual(s.selectedIndex, 5);
    XCTAssertEqual(s.verticalTopVisibleLine, 2); // window only re-scrolls when the highlight passes its top edge
}

#pragma mark - Grid

- (void)testGridFirstDownPressExpandsWithoutMoving {
    CandidatePanelState *s = [self gridWithCount:20];
    XCTAssertFalse(s.gridIsExpanded);
    [s gridMoveDown];
    XCTAssertTrue(s.gridIsExpanded);
    XCTAssertEqual(s.selectedIndex, 0);
}

- (void)testGridSecondDownPressMovesToNextRow {
    CandidatePanelState *s = [self gridWithCount:20];
    [s gridMoveDown];
    [s gridMoveDown];
    XCTAssertEqual(s.gridActiveRow, 1);
    XCTAssertEqual(s.selectedIndex, 5);
}

- (void)testGridDownClampsAtLastRow {
    CandidatePanelState *s = [self gridWithCount:12]; // 3 rows
    [s gridMoveDown];
    [s gridMoveDown];
    [s gridMoveDown];
    [s gridMoveDown]; // clamps
    XCTAssertEqual(s.gridActiveRow, 2);
    XCTAssertEqual(s.selectedIndex, 10);
}

- (void)testGridUpCollapsesAtRowZero {
    CandidatePanelState *s = [self gridWithCount:20];
    [s gridMoveDown];
    [s gridMoveDown]; // row 1
    [s gridMoveUp];   // back to row 0
    XCTAssertTrue(s.gridIsExpanded);
    XCTAssertEqual(s.selectedIndex, 0);
    [s gridMoveUp]; // collapses
    XCTAssertFalse(s.gridIsExpanded);
    XCTAssertEqual(s.selectedIndex, 0);
}

- (void)testGridColumnCyclesWithinRow {
    CandidatePanelState *s = [self gridWithCount:7];
    XCTAssertEqual(s.selectedIndex, 0);
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 1);
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 2);
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 3);
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 4);
    [s gridMoveRight]; // column 4 wraps to 0 (5 columns)
    XCTAssertEqual(s.selectedIndex, 0);
    [s gridMoveLeft]; // column 0 wraps backwards to 4
    XCTAssertEqual(s.selectedIndex, 4);
}

- (void)testGridVisibleWindowScrolls {
    CandidatePanelState *s = [self gridWithCount:50];
    XCTAssertEqual(s.gridRenderedRowCount, 1);
    [s gridMoveDown]; // expand
    XCTAssertEqual(s.gridRenderedRowCount, MIN(s.gridTotalRows, 5));
    for (NSInteger i = 0; i < 7; i++) {
        [s gridMoveDown];
    }
    XCTAssertEqual(s.gridActiveRow, 7);
    XCTAssertEqual(s.gridVisibleRowOffset, 3); // active row inside the 5-row window
    [s gridMoveUp];
    [s gridMoveUp];
    XCTAssertEqual(s.gridVisibleRowOffset, 3); // window only re-scrolls at its top edge
}

- (void)testGridLastRowHasFewerColumns {
    CandidatePanelState *s = [self gridWithCount:12];
    [s gridMoveDown]; // expand
    [s gridMoveDown]; // row 1
    [s gridMoveDown]; // row 2, only 2 cells
    XCTAssertEqual(s.selectedIndex, 10);
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 11);
    [s gridMoveRight]; // wraps within the 2 cells back to column 0
    XCTAssertEqual(s.selectedIndex, 10);
}

- (void)testEmptyCandidatesAreSafe {
    CandidatePanelState *s = [[CandidatePanelState alloc] initWithCandidates:@[] layout:CandidatePanelLayoutGrid];
    [s gridMoveDown];
    [s gridMoveRight];
    XCTAssertEqual(s.selectedIndex, 0);
    XCTAssertEqual(s.gridTotalRows, 0);
}

@end
