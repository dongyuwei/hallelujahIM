
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

- (void)testGetAnnotationOfUpperCaseWord {
    NSString *annotation = [self.engine getAnnotation:@"Test"];
    NSArray *list = @[ @"[tɛst]", @"n. 考验；试验；测试", @"vt. 试验；测试；接受测验" ];
    XCTAssertTrue([[list componentsJoinedByString:@"\n"] isEqualToString:annotation]);
}

- (void)testGetSuggestionOfSpellChecker {
    NSArray *suggestions = [self.engine getSuggestionOfSpellChecker:@"aosome"];
    XCTAssertTrue([[suggestions componentsJoinedByString:@";"] isEqualToString:@"Amos;assume;awesome;assumes"]);

    NSArray *suggestions2 = [self.engine getSuggestionOfSpellChecker:@"Ausome"];
    XCTAssertTrue([[suggestions2 componentsJoinedByString:@";"] isEqualToString:@"Assume;Amos;ASME;assume;awesome;outcome"]);

    NSArray *suggestions3 = [self.engine getSuggestionOfSpellChecker:@"kerrage"];
    XCTAssertTrue([[suggestions3 componentsJoinedByString:@";"] isEqualToString:@"Kerrie;kerne;courage;carriage"]);

    NSArray *suggestions4 = [self.engine getSuggestionOfSpellChecker:@"cerrage"];
    XCTAssertTrue([[suggestions4 componentsJoinedByString:@";"] isEqualToString:@"courage;courage;carriage"]);

    NSArray *suggestions5 = [self.engine getSuggestionOfSpellChecker:@"Awsome"];
    XCTAssertTrue([[suggestions5 componentsJoinedByString:@";"] isEqualToString:@"Awesome;awesome;assume"]);
}

- (void)testGetCandidates {
    NSArray *candidates = [self.engine getCandidates:@"tes"];
    XCTAssertTrue(candidates.count == 50);
    NSArray *words5 = [candidates subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"tes;test;testing;tests;tested"]);

    NSArray *candidates2 = [self.engine getCandidates:@"ceshi"];
    XCTAssertTrue(candidates2.count == 21);
    NSArray *words10 = [candidates2 subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 componentsJoinedByString:@","]
        isEqualToString:@"ceshi,cash,cushy,case,cases,cisco,测试,to test (machinery etc),to test (students),test"]);

    NSArray *candidates3 = [self.engine getCandidates:@"awsome"];
    XCTAssertTrue(candidates3.count == 4);
    NSArray *words4 = [candidates3 subarrayWithRange:NSMakeRange(0, 4)];
    XCTAssertTrue([[words4 componentsJoinedByString:@","] isEqualToString:@"awsome,awesome,assume,assumes"]);
}

- (void)testGetCandidatesWithUpperCaseInput {
    NSArray *candidates = [self.engine getCandidates:@"Tes"];
    XCTAssertTrue(candidates.count == 50);
    NSArray *words5 = [candidates subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"Tes;Test;Testing;Tests;Tested"]);

    NSArray *candidates2 = [self.engine getCandidates:@"Ceshi"];
    XCTAssertTrue(candidates2.count == 21);
    NSArray *words10 = [candidates2 subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 componentsJoinedByString:@","]
        isEqualToString:@"Ceshi,cash,cushy,case,cases,cisco,测试,to test (machinery etc),to test (students),test"]);

    NSArray *candidates3 = [self.engine getCandidates:@"Awsome"];
    XCTAssertTrue(candidates3.count == 4);
    NSArray *words4 = [candidates3 subarrayWithRange:NSMakeRange(0, 4)];
    XCTAssertTrue([[words4 componentsJoinedByString:@","] isEqualToString:@"Awsome,awesome,assume,assumes"]);
}

- (void)testGetPinyinCandidates {
    NSArray *candidates = [self.engine getCandidates:@"xihongshi"];
    XCTAssertTrue(candidates.count == 4);
    NSArray *words3 = [candidates subarrayWithRange:NSMakeRange(0, 3)];
    XCTAssertTrue([[words3 componentsJoinedByString:@";"] isEqualToString:@"xihongshi;西红柿;tomato"]);

    NSArray *candidates2 = [self.engine getCandidates:@"xhs"];
    XCTAssertTrue(candidates2.count == 26);
    NSArray *words = [candidates2 subarrayWithRange:NSMakeRange(0, 26)];
    XCTAssertTrue([[words componentsJoinedByString:@";"]
        isEqualToString:
            @"xhs;新华社;Xinhua News Agency;西红柿;tomato;CL:隻|只;循环赛;round-robin tournament;新化市;Xinhua city in Hunan;新会市;Xinhui "
            @"city in Guangdong;消火栓;fire hydrant;猩红色;scarlet (color);兴化市;Xinghua county level city in Taizhou 泰州;蟹黄水;crab "
            @"roe;crab spawn;(used for crab meat in general);血红素;hemoglobin;须后水;aftershave"]);
}

@end
