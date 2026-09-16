
#import "ConversionEngine.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <XCTest/XCTest.h>

@interface TestConversionEngine : XCTestCase
@property ConversionEngine *engine;
@end

@implementation TestConversionEngine

- (void)setUp {
    self.engine = [ConversionEngine sharedEngine];
    // The dictionaries are preloaded on a background queue at startup; wait so
    // the assertions below see them.
    [self.engine waitForPreparedData];
}

- (void)testWordsStartsWith {
    NSArray *words = [self.engine wordsStartsWith:@"tes"];
    XCTAssertEqual(words.count, 50U); // capped at the panel's candidate limit
    NSArray *words5 = [words subarrayWithRange:NSMakeRange(0, 5)];
    XCTAssertTrue([[words5 componentsJoinedByString:@";"] isEqualToString:@"test;testing;tests;tested;testimonials"]);
    NSArray *words10 = [words subarrayWithRange:NSMakeRange(0, 10)];
    XCTAssertTrue([[words10 componentsJoinedByString:@";"]
        isEqualToString:@"test;testing;tests;tested;testimonials;testimony;testament;tester;testified;testers"]);
}

// The prefix lookup is a B-tree range (`word >= prefix AND word < prefix +
// U+10FFFF`) rather than LIKE: same words, but it uses idx_word instead of
// scanning all 140k rows.
- (void)testWordsStartsWithRangeBoundaries {
    // a whole word that is also a prefix is itself the first match
    XCTAssertTrue([[[self.engine wordsStartsWith:@"in"] objectAtIndex:0] isEqualToString:@"in"]);
    // the range is exact: nothing that sorts after the prefix leaks in
    NSArray *testamentWords = [self.engine wordsStartsWith:@"testament"];
    XCTAssertEqual(testamentWords.count, 3U);
    for (NSString *word in testamentWords) {
        XCTAssertTrue([word hasPrefix:@"testament"]);
    }
    XCTAssertEqual([self.engine wordsStartsWith:@"notaword"].count, 0U);
    XCTAssertEqual([self.engine wordsStartsWith:@"zz"].count, 5U);
    // non-ASCII input must not break the range bound
    XCTAssertEqual([self.engine wordsStartsWith:@"日本語"].count, 0U);
    XCTAssertEqual([self.engine wordsStartsWith:@"caFé"].count, 0U);
}

- (void)testWordsStartsWithFoldsCase {
    NSArray *upper = [self.engine wordsStartsWith:@"TES"];
    NSArray *lower = [self.engine wordsStartsWith:@"tes"];
    XCTAssertTrue([upper isEqualToArray:lower]);
}

// LIKE treated `_` and `%` from the typed prefix as wildcards; a range query
// treats them as literal characters.
- (void)testWordsStartsWithTreatsWildcardsLiterally {
    XCTAssertEqual([self.engine wordsStartsWith:@"a_c"].count, 0U);
    XCTAssertEqual([self.engine wordsStartsWith:@"a%c"].count, 0U);
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

- (void)testGetPhonexEncodedWordsLoadsJSON {
    NSDictionary *encodedWords = [self.engine getPhonexEncodedWords];
    XCTAssertNotNil(encodedWords);
    XCTAssertGreaterThan(encodedWords.count, 0U);
}

// The phonex dictionary is preloaded on a background queue, so the properties
// are nil until -waitForPreparedData returns; the lookups that use them have to
// work afterwards.
- (void)testPreparedDataLoadsThePhonexDictionary {
    [self.engine waitForPreparedData];
    XCTAssertNotNil(self.engine.phonexEncoded);
    XCTAssertGreaterThan(self.engine.phonexEncoded.count, 0U);
    XCTAssertNotNil(self.engine.phonexEncoder);
}

// The wrapper around the JavaScriptCore function, including its nil guard.
- (void)testPhonexEncodeWrapper {
    [self.engine waitForPreparedData];
    XCTAssertEqualObjects([self.engine phonexEncode:@"test"], @"T23");
    XCTAssertEqualObjects([self.engine phonexEncode:@"courage"], [self.engine phonexEncode:@"cerrage"]);
}

#pragma mark - Bundled database and migration

// CI runs on a clean runner, so Application Support starts empty and
// initDatabase: always takes the "copy the bundled database" branch. A schema
// version that disagrees with the code is therefore invisible to CI while
// breaking every existing install: the copy is replaced on every launch, or -
// after a table rename that forgot to bump the version - the pinyin rows
// silently disappear for users who already had a copy. These tests pin the
// contract that dictionary/build-sqlite.py and ConversionEngine must keep.
- (NSString *)bundledDatabasePath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation_and_ipa" ofType:@"sqlite3"];
    XCTAssertNotNil(path, @"the app bundle must ship the words database");
    return path;
}

- (void)testBundledDatabaseSchemaVersionMatchesTheAppsExpectation {
    XCTAssertEqual([ConversionEngine schemaVersionOfDatabaseAtPath:[self bundledDatabasePath]],
                   [ConversionEngine expectedDatabaseSchemaVersion]);
}

- (void)testBundledDatabaseHasCedictPinyinAndNoDeadSchema {
    FMDatabase *db = [FMDatabase databaseWithPath:[self bundledDatabasePath]];
    XCTAssertTrue([db open]);
    XCTAssertTrue([db tableExists:@"words"]);
    XCTAssertTrue([db tableExists:@"cedict_pinyin"]);
    XCTAssertFalse([db tableExists:@"ngrams"], @"the unused ngrams table is not referenced by src/");
    XCTAssertFalse([db tableExists:@"pinyin"], @"the pre-rename name of cedict_pinyin must not ship");
    XCTAssertEqual([db intForQuery:@"SELECT count(*) FROM sqlite_master WHERE type='index' AND name='idx_word'"], 0,
                   @"idx_word duplicates the PRIMARY KEY's implicit index");
    [db close];
}

// The probe once opened read-only, which fails on a WAL database (SQLite has to
// create the -shm file). The failure is indistinguishable from an unset
// version, so it reported 0 for a migrated database and made the app re-copy it
// on every launch. Both journal modes have to read back correctly.
- (void)testSchemaVersionProbeHandlesEveryJournalMode {
    for (NSString *mode in @[ @"DELETE", @"WAL" ]) {
        NSString *path =
            [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"schema-probe-%@.sqlite3", mode]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:path error:nil];
        [fileManager removeItemAtPath:[path stringByAppendingString:@"-wal"] error:nil];
        [fileManager removeItemAtPath:[path stringByAppendingString:@"-shm"] error:nil];

        FMDatabase *db = [FMDatabase databaseWithPath:path];
        XCTAssertTrue([db open]);
        NSString *appliedMode = [db stringForQuery:[NSString stringWithFormat:@"PRAGMA journal_mode = %@", mode]];
        XCTAssertEqualObjects(appliedMode.uppercaseString, mode);
        [db executeUpdate:@"PRAGMA user_version = 7"];
        XCTAssertEqual([db intForQuery:@"PRAGMA user_version"], 7);
        [db close];

        XCTAssertEqual([ConversionEngine schemaVersionOfDatabaseAtPath:path], 7, @"journal mode %@", mode);
    }
}

- (void)testSchemaVersionProbeReportsUnreadableDatabase {
    XCTAssertEqual([ConversionEngine schemaVersionOfDatabaseAtPath:@"/nonexistent-hallelujah-test/nope.sqlite3"], -1);
}

@end
