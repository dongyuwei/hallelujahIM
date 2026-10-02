#import "CandidateTheme.h"
#import <XCTest/XCTest.h>

@interface TestCandidateTheme : XCTestCase
@end

@implementation TestCandidateTheme

- (void)testAllSkinIDs {
    XCTAssertEqualObjects([CandidateTheme allSkinIDs], (@[ @"classic", @"verdant", @"carbon", @"graphite", @"matrix", @"tangerine" ]));
}

- (void)testDefaultSkinIsMatrix {
    XCTAssertEqualObjects([CandidateTheme defaultSkinID], @"matrix");
}

- (void)testThemeForKnownSkin {
    XCTAssertEqualObjects([CandidateTheme themeForSkinID:@"matrix"].skinID, @"matrix");
    XCTAssertEqual([CandidateTheme themeForSkinID:@"matrix"].backgroundColor, 0x1B2530);
    XCTAssertEqual([CandidateTheme themeForSkinID:@"tangerine"].borderColor, 0xFF7A1E);
}

// Unknown and nil fall back to the default skin, so a stale preference value
// can never render an all-black palette.
- (void)testThemeForUnknownSkinFallsBackToDefault {
    XCTAssertEqualObjects([CandidateTheme themeForSkinID:@"nope"].skinID, [CandidateTheme defaultSkinID]);
    XCTAssertEqualObjects([CandidateTheme themeForSkinID:nil].skinID, [CandidateTheme defaultSkinID]);
}

// Every skin must paint a visible highlight: the pill differs from the
// background and the active word differs from the pill.
- (void)testEverySkinHasVisibleHighlight {
    for (NSString *skinID in [CandidateTheme allSkinIDs]) {
        CandidateTheme *theme = [CandidateTheme themeForSkinID:skinID];
        XCTAssertNotEqual(theme.pillColor, theme.backgroundColor, @"%@", skinID);
        XCTAssertNotEqual(theme.wordActiveColor, theme.pillColor, @"%@", skinID);
        XCTAssertGreaterThan(theme.cornerRadius, 0, @"%@", skinID);
    }
}

- (void)testSkinsAreVisuallyDistinct {
    CandidateTheme *verdant = [CandidateTheme themeForSkinID:@"verdant"];
    CandidateTheme *carbon = [CandidateTheme themeForSkinID:@"carbon"];
    XCTAssertLessThan(carbon.backgroundColor, 0x400000);
    XCTAssertGreaterThan(verdant.backgroundColor, 0x800000);
}

@end
