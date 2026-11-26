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

- (NSArray<NSString *> *)candidateTexts {
    return [[self.engine candidates:self.session] valueForKey:@"text"];
}

- (void)assertFirstCandidate:(NSString *)expected forKeys:(NSString *)keys {
    [self.engine clearComposition:self.session];
    [self type:keys];
    XCTAssertEqualObjects(self.candidateTexts.firstObject, expected, @"input: %@", keys);
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

- (void)testCalibratedTechnicalTerms {
    NSDictionary<NSString *, NSString *> *cases = @{
        @"jianzhihuancun" : @"键值缓存",
        @"dizhizishiying" : @"低秩自适应",
        @"qianzhuishu" : @"前缀树",
        @"midengxing" : @"幂等性",
        @"kechongru" : @"可重入",
        @"kvhuancun" : @"KV缓存",
        @"loraweitiao" : @"LoRA微调",
    };
    for (NSString *keys in cases) {
        [self assertFirstCandidate:cases[keys] forKeys:keys];
    }
}

- (void)testCsAiDoesNotChangeCommonWordRanking {
    NSDictionary<NSString *, NSString *> *cases = @{
        @"nihao" : @"你好",
        @"zhongguo" : @"中国",
        @"wenti" : @"问题",
        @"jisuan" : @"计算",
        @"moxing" : @"模型",
        @"jiedian" : @"节点",
        @"lianghua" : @"量化",
    };
    for (NSString *keys in cases) {
        [self assertFirstCandidate:cases[keys] forKeys:keys];
    }
}

- (void)testImportedTermsDoNotDuplicateCandidates {
    [self type:@"shenduxuexi"];
    NSArray<NSString *> *texts = self.candidateTexts;
    XCTAssertEqualObjects(texts.firstObject, @"深度学习");
    XCTAssertEqual(texts.count, [NSSet setWithArray:texts].count);
}

// The pinyin panel only shows English rows on page 0, so the page number has
// to follow candidate paging.
- (void)testPageFollowsPaging {
    [self type:@"nihao"];
    XCTAssertEqual([self.engine page:self.session], 0);

    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_Page_Down mask:0]);
    XCTAssertEqual([self.engine page:self.session], 1);

    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_Page_Up mask:0]);
    XCTAssertEqual([self.engine page:self.session], 0);
}

// One BackSpace has to remove one letter all the way down to the empty
// composition; the input method relies on that for its inline marked text.
- (void)testBackspaceClearsOneLetterAtATime {
    [self type:@"nh"];
    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_BackSpace mask:0]);
    XCTAssertEqualObjects([self.engine rawInput:self.session], @"n");

    XCTAssertTrue([self.engine processKey:self.session keycode:RimeXK_BackSpace mask:0]);
    XCTAssertEqualObjects([self.engine rawInput:self.session], @"");
    XCTAssertEqualObjects([self.engine preedit:self.session selStart:nil selLength:nil caretPos:nil], @"");

    XCTAssertFalse(
        [self.engine processKey:self.session keycode:RimeXK_BackSpace mask:0],
        @"backspace on an empty composition falls through to the client, which is why the input method must clear its marked text itself");
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

// The keep-alive session holds the loaded schema open so the user's first pinyin
// keystroke does not pay for loading it. It has to be idempotent (the app calls
// it at startup and the tests call it again) and must not disturb normal
// sessions.
- (void)testWarmUpSessionIsIdempotentAndLeavesSessionsUsable {
    [self.engine warmUpSession];
    [self.engine warmUpSession];

    RimeSessionId session = [self.engine createSession];
    XCTAssertNotEqual(session, 0U);
    XCTAssertTrue([self.engine processKey:session keycode:KeySymForChar('n') mask:0]);
    XCTAssertTrue([self.engine processKey:session keycode:KeySymForChar('i') mask:0]);
    NSArray<RimeCandidateItem *> *candidates = [self.engine candidates:session];
    XCTAssertGreaterThan(candidates.count, 0U);
    [self.engine destroySession:session];
}

// Pinyin is opt-in, so with the preference off librime is never started, yet
// deactivateServer: calls clearComposition: in every input mode. Calling any
// method on a never-started engine used to deref a NULL RimeApi and SIGSEGV.
- (void)testAllMethodsAreSafeNoOpsBeforeStart {
    RimeEngine *unstarted = [[RimeEngine alloc] init];

    [unstarted clearComposition:0];
    [unstarted clearComposition:123]; // stale session ids must be ignored too
    XCTAssertFalse([unstarted sessionAlive:123]);
    XCTAssertEqual([unstarted createSession], 0U);
    [unstarted destroySession:123];
    XCTAssertFalse([unstarted processKey:123 keycode:RimeXK_a mask:0]);
    XCTAssertEqualObjects([unstarted commitText:123], @"");
    XCTAssertEqualObjects([unstarted rawInput:123], @"");
    XCTAssertEqualObjects([unstarted candidates:123], @[]);
    XCTAssertEqual([unstarted highlightedIndex:123], -1);
    XCTAssertFalse([unstarted selectCandidateOnCurrentPage:123 index:0]);
    NSInteger selStart = -1, selLength = -1, caretPos = -1;
    XCTAssertEqualObjects([unstarted preedit:123 selStart:&selStart selLength:&selLength caretPos:&caretPos], @"");
    XCTAssertEqual(selStart, 0);
    XCTAssertEqual(selLength, 0);
    XCTAssertEqual(caretPos, 0);

    [unstarted warmUpSession];
    [unstarted shutdown];
}

@end
