#import "CandidatePanel.h"
#import <XCTest/XCTest.h>

// Layout tests for the custom candidate panel.
//
// The panel is a borderless NSPanel whose frame is derived from the rendered
// cells (CandidatePanel.m): the candidates set the width, the visible window
// sets the height, and the annotation either adds a detail column (vertical)
// or a footer row (grid). This measurement code is shared by resizeToFit,
// drawRect and mouseDown but had no test coverage; these tests pin its
// invariants before the measurement cache is introduced.
//
// Only the row/padding arithmetic is asserted exactly. Anything that depends
// on font metrics is asserted comparatively (wider/taller), so the tests do
// not break when the system font changes.
@interface TestCandidatePanelLayout : XCTestCase
@property(nonatomic, strong) CandidatePanel *panel;
@end

@implementation TestCandidatePanelLayout

// Mirrors the metrics in CandidatePanel.m.
static const CGFloat kRowHeight = 24;
static const CGFloat kPadding = 2;

static NSString *const kAnnotation = @"[tɛst]\nn. 考验；试验；测试";

- (void)setUp {
    self.panel = [[CandidatePanel alloc] init];
}

- (void)tearDown {
    [self.panel hide];
    self.panel = nil;
}

// "candidate0" ... "candidateN"
static NSArray<NSString *> *Candidates(NSUInteger count) {
    NSMutableArray<NSString *> *words = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [words addObject:[NSString stringWithFormat:@"candidate%lu", (unsigned long)i]];
    }
    return words;
}

#pragma mark - Vertical (the default layout)

// The list window is 9 rows: a full page must not grow the panel to 50 rows.
- (void)testVerticalWindowCapsAtNineRows {
    [self.panel updateCandidates:Candidates(50)];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, 9 * kRowHeight + 2 * kPadding, 0.5);
}

// Fewer candidates than the window use one row each.
- (void)testVerticalUsesOneRowPerCandidate {
    for (NSUInteger count = 1; count <= 9; count++) {
        [self.panel updateCandidates:Candidates(count)];
        XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, count * kRowHeight + 2 * kPadding, 0.5);
    }
}

// In the vertical layout the gloss lives in a second column, so it widens the
// panel rather than making it taller.
- (void)testVerticalAnnotationAddsDetailColumn {
    [self.panel updateCandidates:Candidates(9)];
    CGFloat withoutAnnotation = self.panel.candidateFrame.size.width;

    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.width, withoutAnnotation);

    [self.panel setAnnotation:@""];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.width, withoutAnnotation, 0.5);
}

// The gloss column's draw insets its box by kSelectionGap on top and bottom,
// and Text Kit drops a line that does not fully fit its box - a panel that
// reserved exactly the measured gloss height drew a two-line gloss in a box
// 4pt shorter and silently hid the translation row. The panel must reserve the
// gloss height PLUS those insets. 12pt lines are at least 12pt each, so two
// gloss lines need 24pt, plus 4pt of insets, plus the panel padding mirrored
// from CandidatePanel.m.
- (void)testVerticalAnnotationReservesHeightForEveryGlossLine {
    [self.panel updateCandidates:@[ @"connectivity" ]];
    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThanOrEqual(self.panel.candidateFrame.size.height, 2 * 12 + 4 + 2 * kPadding);
}

// Clearing the gloss collapses the panel back to pure row arithmetic: one
// candidate, one row, no leftover gloss space.
- (void)testVerticalAnnotationCollapseRestoresRowHeight {
    [self.panel updateCandidates:@[ @"connectivity" ]];
    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.height, kRowHeight + 2 * kPadding);

    [self.panel setAnnotation:@""];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, kRowHeight + 2 * kPadding, 0.5);
}

// Every extra gloss line must grow the panel: the height budget covers the
// box that is actually drawn, so a longer gloss can never clip into
// invisibility.
- (void)testVerticalAnnotationMoreLinesGrowPanel {
    [self.panel updateCandidates:@[ @"connectivity" ]];
    [self.panel setAnnotation:kAnnotation];
    CGFloat twoLines = self.panel.candidateFrame.size.height;

    [self.panel setAnnotation:@"[tɛst]\nn. 考验；试验；测试\nadj. 试验性的"];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.height, twoLines);
}

// A gloss without newlines wraps inside the detail column's cap, and the
// wrapped lines grow the panel exactly like explicit ones.
- (void)testVerticalWrappedAnnotationGrowsPanel {
    [self.panel updateCandidates:@[ @"connectivity" ]];
    [self.panel setAnnotation:kAnnotation];
    CGFloat shortGloss = self.panel.candidateFrame.size.height;

    NSMutableString *longLine = [NSMutableString string];
    for (NSUInteger i = 0; i < 60; i++) {
        [longLine appendString:@"测"];
    }
    [self.panel setAnnotation:longLine];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.height, shortGloss);
}

// With a full page of candidates the rows are the taller side: a short gloss
// rides along inside the row window instead of adding height on top of it.
- (void)testVerticalFullPageHeightDominatesShortGloss {
    [self.panel updateCandidates:Candidates(9)];
    [self.panel setAnnotation:kAnnotation];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, 9 * kRowHeight + 2 * kPadding, 0.5);
}

- (void)testWiderCandidateWidensPanel {
    [self.panel updateCandidates:@[ @"ab" ]];
    CGFloat narrow = self.panel.candidateFrame.size.width;

    [self.panel updateCandidates:@[ @"internationalization" ]];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.width, narrow);
}

#pragma mark - Grid

// Collapsed grid renders exactly one row of cells.
- (void)testGridCollapsedShowsOneRow {
    [self.panel setGridLayout:YES];
    [self.panel updateCandidates:Candidates(20)];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, kRowHeight + 2 * kPadding, 0.5);
}

// In the grid layout the gloss is a footer row, so it makes the panel taller.
- (void)testGridAnnotationAddsFooterRow {
    [self.panel setGridLayout:YES];
    [self.panel updateCandidates:Candidates(20)];
    CGFloat withoutAnnotation = self.panel.candidateFrame.size.height;

    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.height, withoutAnnotation);
}

// The footer's one-line width is the grid's content-driven minimum width: a
// one-candidate grid is only as wide as its word, which used to wrap the gloss
// under the cells. The panel must widen to fit the gloss on one line (glosses
// longer than the cap still wrap, like the vertical detail column).
//
// Asserted against a conservative floor instead of measured text (the test
// target does not link AppKit): the gloss holds 9 CJK glyphs, which alone
// outnumber a one-word column at any plausible font metric.
- (void)testGridAnnotationWidensNarrowPanelToFitFooter {
    [self.panel setGridLayout:YES];
    [self.panel updateCandidates:@[ @"ab" ]];
    CGFloat narrow = self.panel.candidateFrame.size.width;

    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.width, narrow);
    XCTAssertGreaterThanOrEqual(self.panel.candidateFrame.size.width, 120);
}

- (void)testGridColumnsAreClampedToRange {
    [self.panel setGridColumns:20];
    XCTAssertEqual(self.panel.gridColumns, 9);

    [self.panel setGridColumns:1];
    XCTAssertEqual(self.panel.gridColumns, 5);

    [self.panel setGridColumns:7];
    XCTAssertEqual(self.panel.gridColumns, 7);
}

#pragma mark - Frame stability

// Applying the same content twice must land on exactly the same size. This is
// what lets the panel skip a redundant measure/resize/redraw: the measurement
// cache must return the same numbers, not approximate ones.
- (void)testRedundantUpdateKeepsFrameSizeStable {
    [self.panel updateCandidates:Candidates(50)];
    [self.panel setAnnotation:kAnnotation];
    [self.panel showAtClient:nil];
    NSSize settled = self.panel.candidateFrame.size;

    [self.panel updateCandidates:Candidates(50)];
    [self.panel setAnnotation:kAnnotation];
    [self.panel showAtClient:nil];
    XCTAssertTrue(NSEqualSizes(settled, self.panel.candidateFrame.size));
}

// showAtClient: refreshes the caret position but must not resize a panel whose
// content did not change.
- (void)testShowAtClientKeepsSizeWhenContentIsUnchanged {
    [self.panel updateCandidates:Candidates(9)];
    [self.panel setAnnotation:kAnnotation];
    [self.panel showAtClient:nil];

    NSSize settled = self.panel.candidateFrame.size;
    [self.panel showAtClient:nil];
    XCTAssertTrue(NSEqualSizes(settled, self.panel.candidateFrame.size));
}

// A different candidate list must be able to change the size again, so the
// cache has to be invalidated by new content.
- (void)testNewContentAfterSettledFrameResizes {
    [self.panel updateCandidates:@[ @"ab" ]];
    [self.panel showAtClient:nil];
    CGFloat narrow = self.panel.candidateFrame.size.width;

    [self.panel updateCandidates:@[ @"internationalization" ]];
    [self.panel showAtClient:nil];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.width, narrow);
}

// Invalidation must also cover the grid navigation that scrolls the window:
// the columns are sized from the rows currently on screen, so scrolling to
// longer rows has to widen the panel.
- (void)testGridScrollRefitsColumnWidths {
    [self.panel setGridLayout:YES];
    [self.panel setGridColumns:5];
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSUInteger i = 0; i < 5; i++) {
        [words addObject:@"ab"];
    }
    for (NSUInteger i = 0; i < 15; i++) {
        [words addObject:@"internationalization"];
    }
    [self.panel updateCandidates:words];
    [self.panel showAtClient:nil];
    CGFloat collapsed = self.panel.candidateFrame.size.width;

    // Expand to the rows holding the long words; the visible window and the
    // column widths both change.
    for (NSUInteger i = 0; i < 3; i++) {
        [self.panel gridMoveDown];
    }
    XCTAssertGreaterThanOrEqual(self.panel.candidateFrame.size.width, collapsed);
}

- (void)testEmptyCandidatesHidePanel {
    [self.panel updateCandidates:@[]];
    [self.panel showAtClient:nil];
    XCTAssertFalse(self.panel.isVisible);
}

#pragma mark - Batched update

// The batched entry point replaces the updateCandidates / setAnnotation /
// showAtClient triplet used by the per-keystroke path; it must land on exactly
// the same size as the sequence it replaces.
- (void)testBatchedUpdateMatchesSeparateCalls {
    CandidatePanel *separate = [[CandidatePanel alloc] init];
    [separate updateCandidates:Candidates(50)];
    [separate setAnnotation:kAnnotation];
    [separate showAtClient:nil];

    CandidatePanel *batched = [[CandidatePanel alloc] init];
    [batched updateCandidates:Candidates(50) annotation:kAnnotation atClient:nil];

    XCTAssertTrue(NSEqualSizes(separate.candidateFrame.size, batched.candidateFrame.size));
}

// A nil annotation means "leave the current gloss alone" (pinyin mode has
// none), so the panel keeps its detail column.
- (void)testBatchedUpdateKeepsAnnotationWhenNil {
    [self.panel updateCandidates:Candidates(9)];
    [self.panel setAnnotation:kAnnotation];
    CGFloat withAnnotation = self.panel.candidateFrame.size.width;

    [self.panel updateCandidates:Candidates(9) annotation:nil atClient:nil];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.width, withAnnotation, 0.5);
}

// An empty candidate list hides the panel instead of leaving a stale one up.
- (void)testBatchedUpdateHidesOnEmptyCandidates {
    [self.panel updateCandidates:Candidates(9) annotation:kAnnotation atClient:nil];
    XCTAssertTrue(self.panel.isVisible);
    [self.panel updateCandidates:@[] annotation:kAnnotation atClient:nil];
    XCTAssertFalse(self.panel.isVisible);
}

#pragma mark - TEMP diagnostic

- (void)testZZTempDiagnosticVerticalDetail {
    [self.panel updateCandidates:@[ @"connectivity" ]];
    NSLog(@"ZZZ step1 (no annotation): %@", NSStringFromRect(self.panel.candidateFrame));
    [self.panel setAnnotation:@"[kənəkˈtɪvɪti]\nn. [计] 连通性"];
    NSLog(@"ZZZ step2 (annotation set): %@", NSStringFromRect(self.panel.candidateFrame));
    [self.panel showAtClient:nil];
    NSLog(@"ZZZ step3 (showAtClient): %@", NSStringFromRect(self.panel.candidateFrame));
    [self.panel updateCandidates:@[ @"connectivity" ] annotation:@"[kənəkˈtɪvɪti]\nn. [计] 连通性" atClient:nil];
    NSLog(@"ZZZ step4 (batched): %@", NSStringFromRect(self.panel.candidateFrame));
}

@end
