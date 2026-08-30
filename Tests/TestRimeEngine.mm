#import "RimeEngine.h"
#import "RimeKeymap.h"
#import <Carbon/Carbon.h>
#import <XCTest/XCTest.h>

static int KeySymForChar(char c) {
    if (c >= 'a' && c <= 'z') {
        return RimeXK_a + (c - 'a');
    }
    return c;
}

@interface TestRimeEngine : XCTestCase
@property RimeEngine *engine;
@property RimeSessionId session;
@end

@implementation TestRimeEngine

- (void)setUp {
    self.engine = [RimeEngine sharedEngine];

    NSString *sharedDataDir = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"rime-data"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:sharedDataDir]) {
        // fallback for runs outside the app bundle: repo layout
        sharedDataDir = [[NSFileManager defaultManager] currentDirectoryPath];
        sharedDataDir = [sharedDataDir stringByAppendingPathComponent:@"rime-data"];
    }
    NSString *userDataDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"hallelujah-rime-tests"];

    [self.engine startWithSharedDataDir:sharedDataDir userDataDir:userDataDir];
    if (self.session == 0) {
        self.session = [self.engine createSession];
    }
    [self.engine clearComposition:self.session];
}

- (void)tearDown {
    [self.engine clearComposition:self.session];
}

- (void)type:(NSString *)keys {
    for (NSUInteger i = 0; i < keys.length; ++i) {
        unichar ch = [keys characterAtIndex:i];
        int keysym = (ch >= 0x20 && ch <= 0x7e) ? KeySymForChar((char)ch) : ch;
        XCTAssertTrue([self.engine processKey:self.session keycode:keysym mask:0], "key '%C' should be handled", ch);
    }
}

- (void)testSessionCreation {
    XCTAssertNotEqual(self.session, 0U);
    XCTAssertTrue([self.engine sessionAlive:self.session]);
}

- (void)testKeymapLetterTranslation {
    int keysym = [RimeKeymap rimeKeycodeForKeyCode:kVK_ANSI_A character:@"a" modifierFlags:0];
    XCTAssertEqual(keysym, RimeXK_a);
    int shifted = [RimeKeymap rimeKeycodeForKeyCode:kVK_ANSI_A character:@"a" modifierFlags:NSEventModifierFlagShift];
    XCTAssertEqual(shifted, RimeXK_a + ('A' - 'a'));
}

- (void)testKeymapNavigationKeys {
    XCTAssertEqual([RimeKeymap rimeKeycodeForKeyCode:kVK_Space character:@" " modifierFlags:0], RimeXK_space);
    XCTAssertEqual([RimeKeymap rimeKeycodeForKeyCode:kVK_Return character:@"\r" modifierFlags:0], RimeXK_Return);
    XCTAssertEqual([RimeKeymap rimeKeycodeForKeyCode:kVK_Delete character:@"" modifierFlags:0], RimeXK_BackSpace);
    XCTAssertEqual([RimeKeymap rimeKeycodeForKeyCode:kVK_Escape character:@"" modifierFlags:0], RimeXK_Escape);
}

- (void)testShiftedPunctuationUsesShiftedCharacter {
    // shift+; must arrive as the colon keysym, the way X11 reports it;
    // librime's punctuator matches on the raw keysym and ignores the mask
    int colon = [RimeKeymap rimeKeycodeForKeyCode:kVK_ANSI_Semicolon character:@":" modifierFlags:NSEventModifierFlagShift];
    XCTAssertEqual(colon, RimeXK_colon);
    int plain = [RimeKeymap rimeKeycodeForKeyCode:kVK_ANSI_Semicolon character:@";" modifierFlags:0];
    XCTAssertEqual(plain, RimeXK_semicolon);
}

- (void)testColonCommitsChineseColon {
    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_colon mask:RimeShiftMask]);
    XCTAssertEqualObjects([self.engine commitText:self.session], @"：");
}

- (void)testPinyinCandidates {
    [self type:@"nihao"];
    NSArray<RimeCandidateItem *> *candidates = [self.engine candidates:self.session];
    XCTAssertEqual(candidates.count, 9U, "page size is 9");
    XCTAssertEqualObjects(candidates.firstObject.text, @"你好");

    NSString *preedit = [self.engine preedit:self.session selStart:nil selLength:nil caretPos:nil];
    XCTAssertEqualObjects(preedit, @"ni hao", @"preedit includes the syllable delimiter");
}

- (void)testSpaceCommitsConvertedText {
    [self type:@"nihao "];
    XCTAssertEqualObjects([self.engine commitText:self.session], @"你好");
    NSString *preedit = [self.engine preedit:self.session selStart:nil selLength:nil caretPos:nil];
    XCTAssertEqualObjects(preedit, @"", @"composition should be gone after commit");
}

- (void)testSimplifiedOutputByDefault {
    [self type:@"nih"];
    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    for (RimeCandidateItem *candidate in [self.engine candidates:self.session]) {
        [texts addObject:candidate.text];
    }
    XCTAssertTrue([texts containsObject:@"你会"], @"simplified output expected, got %@", texts);
    XCTAssertFalse([texts containsObject:@"你會"]);
}

- (void)testEscapeClearsComposition {
    [self type:@"nihao"];
    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_Escape mask:0]);
    NSString *preedit = [self.engine preedit:self.session selStart:nil selLength:nil caretPos:nil];
    XCTAssertEqualObjects(preedit, @"");
    XCTAssertEqualObjects([self.engine rawInput:self.session], @"");
}

- (void)testBackspaceDeletesLastPinyinChar {
    [self type:@"ni"];
    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_BackSpace mask:0]);
    NSString *preedit = [self.engine preedit:self.session selStart:nil selLength:nil caretPos:nil];
    XCTAssertEqualObjects(preedit, @"n");
}

- (void)testChinesePunctuationCommit {
    [self type:@","];
    XCTAssertEqualObjects([self.engine commitText:self.session], @"，");
}

- (void)testSelectCandidateOnCurrentPage {
    [self type:@"nihao"];
    XCTAssertTrue([self.engine selectCandidateOnCurrentPage:self.session index:0]);
    XCTAssertEqualObjects([self.engine commitText:self.session], @"你好");
}

- (void)testHighlightedIndexFollowsSelection {
    [self type:@"nihao"];
    XCTAssertEqual([self.engine highlightedIndex:self.session], 0);
    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_Down mask:0]);
    XCTAssertEqual([self.engine highlightedIndex:self.session], 1);
}

@end
