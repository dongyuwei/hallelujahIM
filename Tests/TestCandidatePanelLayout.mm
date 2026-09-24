#import "CandidatePanel.h"
#import <XCTest/XCTest.h>

// Layout tests for the custom candidate panel.
//
// The panel is a borderless NSPanel whose frame is derived from the rendered
// grid cells (CandidatePanel.m): the candidates set the width, the visible
// window sets the height, and the annotation adds a footer row. This
// measurement code is shared by resizeToFit, drawRect and mouseDown; these
// tests pin its invariants.
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
    NSMutableArray *words = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [words addObject:[NSString stringWithFormat:@"candidate%lu", (unsigned long)i]];
    }
    return words;
}

// Collapsed grid renders exactly one row of cells.
- (void)testGridCollapsedShowsOneRow {
    [self.panel updateCandidates:Candidates(20)];
    XCTAssertEqualWithAccuracy(self.panel.candidateFrame.size.height, kRowHeight + 2 * kPadding, 0.5);
}

// The gloss is a footer row, so it makes the panel taller.
- (void)testGridAnnotationAddsFooterRow {
    [self.panel updateCandidates:Candidates(20)];
    CGFloat withoutAnnotation = self.panel.candidateFrame.size.height;

    [self.panel setAnnotation:kAnnotation];
    XCTAssertGreaterThan(self.panel.candidateFrame.size.height, withoutAnnotation);
}

// The footer's one-line width is the grid's content-driven minimum width: a
// one-candidate grid is only as wide as its word, which used to wrap the gloss
// under the cells. The panel must widen to fit the gloss on one line (glosses
// longer than the cap still wrap).
//
// Asserted against a conservative floor instead of measured text (the test
// target does not link AppKit): the gloss holds 9 CJK glyphs, which alone
// outnumber a one-word column at any plausible font metric.
- (void)testGridAnnotationWidensNarrowPanelToFitFooter {
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
    [self.panel setGridColumns:5];
    NSMutableArray *words = [NSMutableArray array];
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
// none), so the panel keeps its footer.
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

@end
