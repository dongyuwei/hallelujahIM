
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

- (void)testWordsStartsWith {
    NSArray *words = [self.engine wordsStartsWith:@"tes"];
    XCTAssert(words.count == 64);
    XCTAssertTrue([[words objectAtIndex:0] isEqualToString:@"test"]);
    NSArray *words5 = [words subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"test;testing;tests;tested;testimonials"]);
}

- (void)testSortWordsByFrequency {
    NSArray *words = [self.engine wordsStartsWith:@"tes"];
    NSArray *sorted = [self.engine sortWordsByFrequency:words];
    NSArray *words10 = [sorted subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 objectAtIndex:0] isEqualToString:@"test"]);
    XCTAssertTrue([[words10 componentsJoinedByString:@";"]
        isEqualToString:@"test;testing;tests;tested;testimonials;testimony;testament;tester;testified;testers"]);
}

- (void)testSortWordsByFrequencyFromLargeNumberOfCandidates {
    NSArray *words = [self.engine wordsStartsWith:@"in"];
    NSArray *sorted = [self.engine sortWordsByFrequency:words];
    XCTAssertTrue([[sorted objectAtIndex:0] isEqualToString:@"in"]);
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

- (void)testPredictNextWordsWithSingleWordContext {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"i" maxResults:5];
    XCTAssertTrue(predictions.count == 5);
    XCTAssertTrue([[predictions objectAtIndex:0] isEqualToString:@"was"]);
    XCTAssertTrue([[predictions objectAtIndex:1] isEqualToString:@"'m"]);
    XCTAssertTrue([[predictions objectAtIndex:2] isEqualToString:@"do"]);
}

- (void)testPredictNextWordsWithMultiWordContext {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"i do not" maxResults:5];
    XCTAssertTrue(predictions.count == 5);
    XCTAssertTrue([[predictions objectAtIndex:0] isEqualToString:@"know"]);
    XCTAssertTrue([[predictions objectAtIndex:1] isEqualToString:@"think"]);
    XCTAssertTrue([[predictions objectAtIndex:2] isEqualToString:@"want"]);
}

- (void)testPredictNextWordsWithPrefixFilter {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"the" prefixFilter:@"f" maxResults:10];
    XCTAssertTrue(predictions.count > 0);
    for (NSString *word in predictions) {
        XCTAssertTrue([word hasPrefix:@"f"]);
    }
    XCTAssertTrue([[predictions objectAtIndex:0] isEqualToString:@"first"]);
}

- (void)testPredictNextWordsWithPrefixFilterUpperCase {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"the" prefixFilter:@"F" maxResults:10];
    XCTAssertTrue(predictions.count > 0);
    for (NSString *word in predictions) {
        XCTAssertTrue([word hasPrefix:@"f"]);
    }
}

- (void)testPredictNextWordsWithLongContextUsesLastWords {
    NSArray *shortCtx = [self.engine predictNextWordsForContext:@"at the end of" maxResults:5];
    NSArray *longCtx = [self.engine predictNextWordsForContext:@"this is at the end of" maxResults:5];
    XCTAssertEqualObjects([shortCtx objectAtIndex:0], [longCtx objectAtIndex:0]);
}

- (void)testPredictNextWordsWithNilContext {
    NSArray *predictions = [self.engine predictNextWordsForContext:nil maxResults:5];
    XCTAssertTrue(predictions.count == 0);
}

- (void)testPredictNextWordsWithEmptyContext {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"" maxResults:5];
    XCTAssertTrue(predictions.count == 0);
}

- (void)testPredictNextWordsWithContextNotInDatabase {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"xylophone unicorn" maxResults:5];
    XCTAssertTrue(predictions.count == 0);
}

- (void)testPredictNextWordsRespectsMaxResults {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"the" maxResults:3];
    XCTAssertTrue(predictions.count == 3);
}

- (void)testPredictNextWordsNoDuplicates {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"the" maxResults:20];
    NSSet *uniqueSet = [NSSet setWithArray:predictions];
    XCTAssertEqual(predictions.count, uniqueSet.count, @"Predictions should not contain duplicates");
}

- (void)testPredictNextWordsWithWhitespaceContext {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"  i   do  not  " maxResults:5];
    XCTAssertTrue(predictions.count == 5);
    XCTAssertTrue([[predictions objectAtIndex:0] isEqualToString:@"know"]);
}

- (void)testPredictNextWordsContextFallback {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"what i want" maxResults:10];
    XCTAssertTrue(predictions.count > 0);
}

- (void)testPredictNextWordsPrefixFilterNoResults {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"the" prefixFilter:@"xyz" maxResults:5];
    XCTAssertTrue(predictions.count == 0);
}

- (void)testPredictNextWordsSingleCharPrefix {
    NSArray *predictions = [self.engine predictNextWordsForContext:@"of the" prefixFilter:@"w" maxResults:5];
    XCTAssertTrue(predictions.count >= 3);
    for (NSString *word in predictions) {
        XCTAssertTrue([word hasPrefix:@"w"]);
    }
}

#pragma mark - Pinyin Tests

- (void)testFetchHanZiByPinyinFullPinyin {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"niha"];
    XCTAssertTrue(results.count >= 2);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"你好"]);
}

- (void)testFetchHanZiByPinyinAbbreviation {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"nh"];
    XCTAssertTrue(results.count > 0);
    XCTAssertTrue([results containsObject:@"你好"]);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"你好"]);
}

- (void)testFetchHanZiByPinyinEnglishWord {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"ceshi"];
    XCTAssertTrue(results.count >= 3);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"测试"]);
}

- (void)testFetchHanZiByPinyinMultiChar {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"zhongguo"];
    XCTAssertTrue(results.count >= 5);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"中国"]);
    XCTAssertTrue([results containsObject:@"中国人"]);
}

- (void)testFetchHanZiByPinyinAbbreviationFirstResult {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"rj"];
    XCTAssertTrue(results.count >= 3);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"软件"]);
}

- (void)testFetchHanZiByPinyinEmptyInput {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@""];
    XCTAssertTrue(results.count == 0);
}

- (void)testFetchHanZiByPinyinNilInput {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:nil];
    XCTAssertTrue(results.count == 0);
}

- (void)testFetchHanZiByPinyinMaxResults {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"a"];
    XCTAssertTrue(results.count > 0);
    XCTAssertTrue(results.count <= 20);
}

- (void)testFetchHanZiByPinyinNoDuplicates {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"shi"];
    NSSet *uniqueSet = [NSSet setWithArray:results];
    XCTAssertEqual(results.count, uniqueSet.count, @"Pinyin results should not contain duplicates");
}

- (void)testFetchHanZiByPinyinFrequencyOrdering {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"zhongguo"];
    // "中国" should be first since it has the highest frequency
    XCTAssertTrue(results.count > 0);
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"中国"]);
}

- (void)testFetchHanZiByPinyinUpperCaseInput {
    NSArray *lower = [self.engine fetchHanZiByPinyinWithPrefix:@"nihao"];
    NSArray *upper = [self.engine fetchHanZiByPinyinWithPrefix:@"NIHao"];
    XCTAssertEqualObjects(lower, upper);
}

- (void)testFetchHanZiByPinyinSingleSyllableYu {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"yu"];
    XCTAssertTrue(results.count >= 5);
    // Exact py='yu' matches should rank above prefix matches like yue/yuan/yun
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"与"]);
    XCTAssertTrue([[results objectAtIndex:1] isEqualToString:@"于"]);
    XCTAssertTrue([results containsObject:@"玉"]);
}

- (void)testFetchHanZiByPinyinSingleSyllableWei {
    NSArray *results = [self.engine fetchHanZiByPinyinWithPrefix:@"wei"];
    XCTAssertTrue(results.count >= 5);
    // Exact py='wei' matches should rank above prefix matches like weishenme/weizhi
    XCTAssertTrue([[results objectAtIndex:0] isEqualToString:@"为"]);
    XCTAssertTrue([[results objectAtIndex:1] isEqualToString:@"未"]);
    XCTAssertTrue([results containsObject:@"伟"]);
}

- (void)testGetPinyinDataLoadsCedictJSON {
    NSDictionary *pinyinData = [self.engine getPinyinData];
    XCTAssertNotNil(pinyinData);
    XCTAssertGreaterThan(pinyinData.count, 0U);
}

- (void)testGetPhonexEncodedWordsLoadsJSON {
    NSDictionary *encodedWords = [self.engine getPhonexEncodedWords];
    XCTAssertNotNil(encodedWords);
    XCTAssertGreaterThan(encodedWords.count, 0U);
}

@end
