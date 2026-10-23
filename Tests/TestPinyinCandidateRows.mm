#import "PinyinCandidateRows.h"
#import <XCTest/XCTest.h>

@interface TestPinyinCandidateRows : XCTestCase
@end

@implementation TestPinyinCandidateRows

static PinyinCandidateRows *Rows(NSString *rawInput, NSArray *rimeCandidates, NSInteger position) {
    return [[PinyinCandidateRows alloc] initWithRawInput:rawInput
                                       englishCandidates:@[]
                                          rimeCandidates:rimeCandidates
                                       preferredPosition:position];
}

static PinyinCandidateRows *MixedRows(NSString *rawInput, NSArray *english, NSArray *rime, NSInteger position) {
    return [[PinyinCandidateRows alloc] initWithRawInput:rawInput englishCandidates:english rimeCandidates:rime preferredPosition:position];
}

- (void)testRawInputSplicedAtConfiguredPosition {
    NSArray *chinese = @[ @"你好", @"尼豪", @"你好吗" ];

    PinyinCandidateRows *second = Rows(@"nihao", chinese, 2);
    XCTAssertEqualObjects(second.rows, (@[ @"你好", @"nihao", @"尼豪", @"你好吗" ]));
    XCTAssertEqual(second.rawInputRow, 1);

    PinyinCandidateRows *fifth = Rows(@"nihao", chinese, 5);
    XCTAssertEqualObjects(fifth.rows, (@[ @"你好", @"尼豪", @"你好吗", @"nihao" ]));
    XCTAssertEqual(fifth.rawInputRow, 3, @"a short page can only offer its last row");

    PinyinCandidateRows *first = Rows(@"nihao", chinese, 1);
    XCTAssertEqualObjects(first.rows, (@[ @"nihao", @"你好", @"尼豪", @"你好吗" ]));
    XCTAssertEqual(first.rawInputRow, 0);
}

- (void)testPositionIsClamped {
    XCTAssertEqual([PinyinCandidateRows clampedPosition:0], [PinyinCandidateRows minPosition]);
    XCTAssertEqual([PinyinCandidateRows clampedPosition:-3], [PinyinCandidateRows minPosition]);
    XCTAssertEqual([PinyinCandidateRows clampedPosition:6], [PinyinCandidateRows maxPosition]);
    XCTAssertEqual([PinyinCandidateRows clampedPosition:99], [PinyinCandidateRows maxPosition]);
    XCTAssertEqual([PinyinCandidateRows clampedPosition:3], 3);
    XCTAssertEqual([PinyinCandidateRows minPosition], 1);
    XCTAssertEqual([PinyinCandidateRows maxPosition], 5);
}

// Rows above the raw-input row keep their Rime page index; rows below it
// shift by one, because the raw input occupies a row of the page.
- (void)testRowIndexMapping {
    NSArray *chinese = @[ @"你好", @"尼豪", @"你好吗", @"拟好" ];
    PinyinCandidateRows *rows = Rows(@"nihao", chinese, 2);

    XCTAssertTrue([rows rowIsRawInput:1]);
    XCTAssertFalse([rows rowIsRawInput:0]);
    XCTAssertFalse([rows rowIsRawInput:2]);

    XCTAssertEqual([rows rimeIndexForRow:0], 0);
    XCTAssertEqual([rows rimeIndexForRow:2], 1);
    XCTAssertEqual([rows rimeIndexForRow:3], 2);
    XCTAssertEqual([rows rimeIndexForRow:4], 3);
}

- (void)testEmptyRawInputYieldsNoRow {
    PinyinCandidateRows *rows = Rows(@"", @[ @"你好", @"尼豪" ], 2);
    XCTAssertEqualObjects(rows.rows, (@[ @"你好", @"尼豪" ]));
    XCTAssertEqual(rows.rawInputRow, NSNotFound);
    XCTAssertFalse([rows rowIsRawInput:0]);
    XCTAssertEqual([rows rimeIndexForRow:0], 0, @"without a raw-input row the mapping is the identity");
    XCTAssertEqual([rows rimeIndexForRow:1], 1);
}

- (void)testEmptyInputAndCandidatesYieldNoRows {
    XCTAssertEqualObjects(Rows(@"", @[], 2).rows, @[]);
    XCTAssertEqualObjects(Rows(nil, @[], 2).rows, @[]);
}

- (void)testRimeCandidatesMayBeNil {
    PinyinCandidateRows *rows = Rows(@"z", nil, 2);
    XCTAssertEqualObjects(rows.rows, (@[ @"z" ]));
    XCTAssertEqual(rows.rawInputRow, 0, @"a candidate-less page puts the raw input at the top");
}

// English completions take the earliest rows other than the configured
// raw-input row, so the raw input keeps its digit.
- (void)testEnglishRowsTakeTheFrontKeepingTheRawInputDigit {
    NSArray *chinese = @[ @"你好", @"尼豪", @"你好吗" ];

    PinyinCandidateRows *second = MixedRows(@"app", @[ @"application", @"applications", @"apply" ], chinese, 2);
    XCTAssertEqualObjects(second.rows, (@[ @"application", @"app", @"applications", @"apply", @"你好", @"尼豪", @"你好吗" ]));
    XCTAssertTrue([second rowIsEnglish:0]);
    XCTAssertFalse([second rowIsEnglish:1]);
    XCTAssertTrue([second rowIsRawInput:1]);
    XCTAssertEqual([second rimeIndexForRow:4], 0);
    XCTAssertEqual([second rimeIndexForRow:5], 1);
    XCTAssertEqual([second rimeIndexForRow:6], 2);

    PinyinCandidateRows *first = MixedRows(@"app", @[ @"application", @"applications" ], chinese, 1);
    XCTAssertEqualObjects(first.rows, (@[ @"app", @"application", @"applications", @"你好", @"尼豪", @"你好吗" ]));
    XCTAssertEqual(first.rawInputRow, 0);

    // a short page: the raw input still lands at the end when configured past it
    PinyinCandidateRows *fifth = MixedRows(@"app", @[ @"application", @"applications" ], @[ @"你好" ], 5);
    XCTAssertEqualObjects(fifth.rows, (@[ @"application", @"applications", @"你好", @"app" ]));
    XCTAssertEqual(fifth.rawInputRow, 3);
}

// When the English candidates include the typed word exactly, that row
// replaces the raw-input row: filtering the word instead would promote a
// longer completion to row 0, and space would commit a word never typed.
- (void)testExactEnglishWordReplacesTheRawInputRow {
    PinyinCandidateRows *rows = MixedRows(@"the", @[ @"the", @"they", @"their" ], @[ @"你好" ], 2);
    XCTAssertEqualObjects(rows.rows, (@[ @"the", @"they", @"their", @"你好" ]));
    XCTAssertEqual(rows.rawInputRow, NSNotFound);
    XCTAssertTrue([rows rowIsEnglish:0]);
    XCTAssertEqual([rows rimeIndexForRow:3], 0);

    // case-insensitive: a capitalized typed word replaces it too
    PinyinCandidateRows *cased = MixedRows(@"The", @[ @"the", @"they" ], @[ @"你好" ], 2);
    XCTAssertEqual(cased.rawInputRow, NSNotFound);
}

- (void)testEnglishRowsWithoutRawInput {
    PinyinCandidateRows *rows = MixedRows(@"", @[ @"the", @"they" ], @[ @"你好", @"尼豪" ], 2);
    XCTAssertEqualObjects(rows.rows, (@[ @"the", @"they", @"你好", @"尼豪" ]));
    XCTAssertEqual(rows.rawInputRow, NSNotFound);
    XCTAssertFalse([rows rowIsEnglish:2]);
    XCTAssertEqual([rows rimeIndexForRow:2], 0);
}

- (void)testRimeIndexForRowOutOfRangeIsNotFound {
    PinyinCandidateRows *rows = MixedRows(@"app", @[ @"application" ], @[ @"你好" ], 2);
    XCTAssertEqual([rows rimeIndexForRow:-1], NSNotFound);
    XCTAssertEqual([rows rimeIndexForRow:99], NSNotFound);
}

@end
