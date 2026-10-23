#import "PinyinSegmenter.h"
#import <XCTest/XCTest.h>

@interface TestPinyinSegmenter : XCTestCase
@end

@implementation TestPinyinSegmenter

- (void)testCompletePinyinSegments {
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"zhongwen"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"nihao"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"shenghuofei"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"shurufa"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"wenti"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"lv"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"rua"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"a"]);
    // strings that are both full pinyin and an English word stay pinyin
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"women"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"name"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"shame"]);
}

- (void)testNonPinyinDoesNotSegment {
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"hello"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"the"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"ok"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"str"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"went"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"main"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"ginger"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"consid"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"qzwxec"]);
    // an incomplete tail is not a complete segmentation
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"sh"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"zhongw"]);
}

- (void)testRejectsEmptyAndNonLetters {
    XCTAssertFalse([PinyinSegmenter canFullySegment:@""]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:nil]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"HELLO"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"wo'men"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"wo men"]);
}

// Marginal syllables the luna_pinyin dictionary and its spelling corrections
// accept; a table that misses one would judge real pinyin English.
- (void)testMarginalSyllables {
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"fo"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"fojiao"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"lue"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"nue"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"lve"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"shei"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"gei"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"rua"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"biang"]);
    // single letters are not syllables (except a, e, o)
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"x"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"c"]);
    XCTAssertFalse([PinyinSegmenter canFullySegment:@"i"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"a"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"e"]);
    XCTAssertTrue([PinyinSegmenter canFullySegment:@"o"]);
}

@end
