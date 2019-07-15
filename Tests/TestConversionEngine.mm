
#import "ConversionEngine.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <XCTest/XCTest.h>

@interface TestConversionEngine : XCTestCase
@property ConversionEngine *engine;
@end

@implementation TestConversionEngine

- (void)setUp {
    self.engine = [ConversionEngine sharedEngine];
}

- (void)testWordsWithFrequencyAndTranslation {
    NSDictionary *dict = self.engine.wordsWithFrequencyAndTranslation;
    NSArray *allKeys = [dict allKeys];
    XCTAssert([allKeys count] == 140402);
    NSDictionary *word = [dict objectForKey:@"test"];
    int frequency = [[word objectForKey:@"frequency"] intValue];
    XCTAssert(frequency == 154999587);
    NSArray *translation = [word objectForKey:@"translation"];
    XCTAssert(translation.count == 2);
}
- (void)testWordsStartsWith {
    NSArray *words = [self.engine wordsStartsWith:@"tes"];
    XCTAssert(words.count == 95);
    NSArray *words5 = [words subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words objectAtIndex:0] isEqualToString:@"test"]);
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"test;testing;testings;testim;testimonial"]);
}

- (void)testSortWordsByFrequency {
    NSArray *words = [self.engine wordsStartsWith:@"tes"];
    NSArray *sorted = [self.engine sortWordsByFrequency:words];
    NSArray *words10 = [sorted subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 objectAtIndex:0] isEqualToString:@"test"]);
    XCTAssertTrue([[words10 componentsJoinedByString:@";"]
        isEqualToString:@"test;testing;tests;tested;testimonials;testimony;testament;tester;testified;testers"]);
}

- (void)testPhonexEncode {
    JSValue *phonexFunc = self.engine.phonexEncoder;
    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"test" ]] toString] isEqualToString:@"T23"]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"courage" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"cerrage" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"kerrage" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"cerrage" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"inderpendent" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"independent" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"aosome" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"awesome" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"ausome" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"awesome" ]] toString]]);
}

- (void)testGetTranslations {
    NSArray *translations = [self.engine getTranslations:@"test"];
    XCTAssertTrue([[translations objectAtIndex:0] isEqualToString:@"n. 考验；试验；测试"]);
    XCTAssertTrue([[translations objectAtIndex:1] isEqualToString:@"vt. 试验；测试；接受测验"]);
}

- (void)testGetPhoneticSymbolOfWord {
    NSString *ipa = [self.engine getPhoneticSymbolOfWord:@"test"];
    XCTAssertTrue([ipa isEqualToString:@"tɛst"]);
}

- (void)testGetAnnotation {
    NSString *annotation = [self.engine getAnnotation:@"test"];
    NSArray *list = @[ @"[tɛst]", @"n. 考验；试验；测试", @"vt. 试验；测试；接受测验" ];
    XCTAssertTrue([[list componentsJoinedByString:@"\n"] isEqualToString:annotation]);
}

- (void)testGetSuggestionOfSpellChecker {
    NSArray *suggestions = [self.engine getSuggestionOfSpellChecker:@"aosome"];
    XCTAssertTrue([[suggestions componentsJoinedByString:@";"] isEqualToString:@"Amos;assume;awesome;assumes"]);

    NSArray *suggestions2 = [self.engine getSuggestionOfSpellChecker:@"ausome"];
    XCTAssertTrue([[suggestions2 componentsJoinedByString:@";"] isEqualToString:@"assume;Amos;assume;awesome;assumes;outcome"]);

    NSArray *suggestions3 = [self.engine getSuggestionOfSpellChecker:@"kerrage"];
    XCTAssertTrue([[suggestions3 componentsJoinedByString:@";"] isEqualToString:@"Kerrie;kerne;courage;carriage"]);

    NSArray *suggestions4 = [self.engine getSuggestionOfSpellChecker:@"cerrage"];
    XCTAssertTrue([[suggestions4 componentsJoinedByString:@";"] isEqualToString:@"courage;courage;carriage"]);

    NSArray *suggestions5 = [self.engine getSuggestionOfSpellChecker:@"awsome"];
    XCTAssertTrue([[suggestions5 componentsJoinedByString:@";"] isEqualToString:@"awesome;awesome;assume;assumes"]);
}

- (void)testGetCandidates {
    NSArray *candidates = [self.engine getCandidates:@"tes"];
    XCTAssertTrue(candidates.count == 50);
    NSArray *words5 = [candidates subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"tes;test;testing;tests;tested"]);

    NSArray *candidates2 = [self.engine getCandidates:@"ceshi"];
    XCTAssertTrue(candidates.count == 50);
    NSArray *words10 = [candidates2 subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 componentsJoinedByString:@","]
        isEqualToString:@"ceshi,cash,cushy,case,cases,cisco,测试,to test (machinery etc),to test (students),test"]);
}

@end
