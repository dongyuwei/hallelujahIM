#import "PinyinCandidateRows.h"
#import <XCTest/XCTest.h>

@interface TestPinyinCandidateRows : XCTestCase
@end

@implementation TestPinyinCandidateRows

- (void)testRawInputIsAlwaysTheFirstRow {
    NSArray *rows = [PinyinCandidateRows rowsForRawInput:@"nihao" rimeCandidates:@[ @"你好", @"尼豪" ]];
    XCTAssertEqualObjects(rows, (@[ @"nihao", @"你好", @"尼豪" ]));
}

- (void)testEmptyRawInputYieldsNoRow {
    NSArray *rows = [PinyinCandidateRows rowsForRawInput:@"" rimeCandidates:@[ @"你好" ]];
    XCTAssertEqualObjects(rows, (@[ @"你好" ]));
}

- (void)testEmptyInputAndCandidatesYieldNoRows {
    XCTAssertEqualObjects([PinyinCandidateRows rowsForRawInput:@"" rimeCandidates:@[]], @[]);
    XCTAssertEqualObjects([PinyinCandidateRows rowsForRawInput:nil rimeCandidates:@[]], @[]);
}

- (void)testRimeCandidatesMayBeNil {
    NSArray *rows = [PinyinCandidateRows rowsForRawInput:@"z" rimeCandidates:nil];
    XCTAssertEqualObjects(rows, (@[ @"z" ]));
}

// Row 0 commits the raw input; the Rime page index of every row below it is
// one less, because the raw input occupies the panel's first row.
- (void)testRowIndexMapping {
    XCTAssertTrue([PinyinCandidateRows rowIsRawInput:0]);
    XCTAssertFalse([PinyinCandidateRows rowIsRawInput:1]);

    XCTAssertEqual([PinyinCandidateRows rimeIndexForRow:1], 0);
    XCTAssertEqual([PinyinCandidateRows rimeIndexForRow:2], 1);
    XCTAssertEqual([PinyinCandidateRows rimeIndexForRow:9], 8);
}

@end
