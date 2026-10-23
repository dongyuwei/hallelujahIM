#import "ConversionEngine.h"

#import "PinyinSegmenter.h"

// The candidate list the panel can show is capped here. The prefix query is
// capped to the same number: without it a one-character prefix returns
// thousands of words and pays for sorting every one of them (see
// wordsStartsWith:).
static const NSUInteger kMaxCandidates = 50;

// English rows shown ahead of the Rime candidates in the pinyin panel.
static const NSUInteger kEnglishCandidateLimit = 3;

// U+10FFFF is the highest Unicode code point, so `prefix + kPrefixUpperBound` is
// the exclusive end of the B-tree range holding every word that starts with
// `prefix`.
static NSString *const kPrefixUpperBound = @"\U0010FFFF";

// Schema version of the bundled words database. It must match the value
// dictionary/build-sqlite.py writes; the copy in Application Support is
// refreshed when it is older.
static const NSInteger kWordsDatabaseSchemaVersion = 3;

// PRAGMA user_version of the database at `path`, or -1 when it cannot be read
// (missing, unreadable, or written by a build that never set it), which makes
// the caller replace its copy.
//
// Opened read-write on purpose: a WAL database cannot be read over a read-only
// connection (SQLite has to create the -shm file), and the failed read looks
// exactly like an unset version - which would re-copy the database on every
// launch. The app opens this database read-write anyway.
static NSInteger wordsDatabaseSchemaVersionAtPath(NSString *path) {
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![db open]) {
        return -1;
    }
    NSInteger version = [db intForQuery:@"PRAGMA user_version"];
    [db close];
    return version;
}

NSDictionary *deserializeJSON(NSString *path) {
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [inputStream open];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:nil];
    [inputStream close];
    return dict;
}

@implementation ConversionEngine {
    FMDatabaseQueue *_dbQueue;
    FMDatabaseQueue *_subDbQueue;
    // Signalled when the background dictionary preload completes; see
    // -waitForPreparedData.
    dispatch_group_t _prepareGroup;
}

+ (instancetype)sharedEngine {
    static dispatch_once_t once;
    static id sharedInstance;

    dispatch_once(&once, ^{
        sharedInstance = [self new];
        [sharedInstance loadPreparedData];
    });
    return sharedInstance;
}

+ (NSInteger)expectedDatabaseSchemaVersion {
    return kWordsDatabaseSchemaVersion;
}

+ (NSInteger)schemaVersionOfDatabaseAtPath:(NSString *)path {
    return wordsDatabaseSchemaVersionAtPath(path);
}

- (void)loadPreparedData {
    [self initDatabase];
    [self initSubstitutionDatabase];
    self.substitutions = [self loadSubstitutionsFromDB];
    // JavaScriptCore values are confined to the thread that created them, so
    // the encoder is built here on the main thread (it is only ~4 ms).
    self.phonexEncoder = [self getPhonexEncoder];
    [self preloadDictionariesInBackground];
}

// phonex_encoded_words.json (~11 ms to parse, ~4 MB resident) used to be parsed
// before [NSApplication run], delaying startup. It is only consulted once the
// first English keystroke falls through to the spelling suggestions, and until
// it arrives the phonex lookups are skipped - the same result they would return
// for an unknown key - so it is loaded on a background queue instead.
- (void)preloadDictionariesInBackground {
    dispatch_group_t group = dispatch_group_create();
    _prepareGroup = group;
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        // Assigned once, from nil, so a reader on the main thread observes
        // either nil (lookup skipped) or the finished dictionary.
        self.phonexEncoded = [self getPhonexEncodedWords];
        dispatch_group_leave(group);
    });
}

- (void)waitForPreparedData {
    if (_prepareGroup) {
        dispatch_group_wait(_prepareGroup, DISPATCH_TIME_FOREVER);
    }
}

- (void)initDatabase {
    NSString *supportDir = [NSString stringWithFormat:@"%@/Library/Application Support/hallelujah", NSHomeDirectory()];
    NSString *dbPath = [supportDir stringByAppendingPathComponent:@"words_with_frequency_and_translation_and_ipa.sqlite3"];

    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation_and_ipa" ofType:@"sqlite3"];
    if (!sourcePath) {
        sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"words_with_frequency_and_translation_and_ipa"
                                                                      ofType:@"sqlite3"];
    }
    if (!sourcePath) {
        NSLog(@"[Hallelujah] ERROR: words_with_frequency_and_translation_and_ipa.sqlite3 not found");
        return;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL needsCopy = ![fileManager fileExistsAtPath:dbPath];
    if (!needsCopy) {
        // The copy only ever mirrors the bundle - the app issues SELECTs
        // against it and never writes - so a copy left over from an older
        // build is replaced rather than patched in place. That is how an
        // existing install picks up new tables (cedict_pinyin) and the removal of the
        // unused ones (ngrams).
        // Any mismatch - older, newer, or unreadable (-1) - is refreshed, since
        // the bundle is the source of truth for this read-only snapshot.
        NSInteger version = wordsDatabaseSchemaVersionAtPath(dbPath);
        if (version != kWordsDatabaseSchemaVersion) {
            NSLog(@"[Hallelujah] Refreshing words database (schema %ld -> %ld)", (long)version, (long)kWordsDatabaseSchemaVersion);
            needsCopy = YES;
        }
    }

    if (needsCopy) {
        [fileManager createDirectoryAtPath:supportDir withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager removeItemAtPath:dbPath error:nil];
        // A WAL database keeps these next to the main file; a stale one must
        // not be replayed against the fresh copy.
        [fileManager removeItemAtPath:[dbPath stringByAppendingString:@"-wal"] error:nil];
        [fileManager removeItemAtPath:[dbPath stringByAppendingString:@"-shm"] error:nil];
        NSError *error = nil;
        [fileManager copyItemAtPath:sourcePath toPath:dbPath error:&error];
        if (error) {
            NSLog(@"[Hallelujah] ERROR: Failed to copy database: %@", error.localizedDescription);
            // If the stale copy is still there, run against it: everything but
            // the pinyin candidates keeps working.
            if (![fileManager fileExistsAtPath:dbPath]) {
                return;
            }
        } else {
            NSLog(@"[Hallelujah] Copied database to user directory: %@", dbPath);
        }
    }

    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    if (!_dbQueue) {
        NSLog(@"[Hallelujah] ERROR: Failed to open database at %@", dbPath);
    }
}

- (NSDictionary *)getPhonexEncodedWords {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"phonex_encoded_words" ofType:@"json"];
    return deserializeJSON(path);
}

- (JSValue *)getPhonexEncoder {
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"phonex" ofType:@"js"];
    NSString *scriptString = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];

    JSContext *context = [[JSContext alloc] init];
    [context evaluateScript:scriptString];
    return context[@"phonex"];
}

- (void)initSubstitutionDatabase {
    NSString *supportDir = [NSString stringWithFormat:@"%@/Library/Application Support/hallelujah", NSHomeDirectory()];
    [[NSFileManager defaultManager] createDirectoryAtPath:supportDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *dbPath = [supportDir stringByAppendingPathComponent:@"substitutions.sqlite3"];

    _subDbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [_subDbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS substitutions (key TEXT PRIMARY KEY, value TEXT)"];
    }];
}

- (NSDictionary *)loadSubstitutionsFromDB {
    if (!_subDbQueue)
        return @{};

    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [_subDbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT key, value FROM substitutions"];
        while ([rs next]) {
            dict[[rs stringForColumn:@"key"]] = [rs stringForColumn:@"value"];
        }
    }];
    return [dict copy];
}

- (NSDictionary *)allSubstitutions {
    if (!_subDbQueue)
        return @{};
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [_subDbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT key, value FROM substitutions"];
        while ([rs next]) {
            dict[[rs stringForColumn:@"key"]] = [rs stringForColumn:@"value"];
        }
    }];
    return [dict copy];
}

- (void)addSubstitution:(NSString *)key value:(NSString *)value {
    if (!_subDbQueue)
        return;
    [_subDbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT OR REPLACE INTO substitutions (key, value) VALUES (?, ?)", key, value];
    }];
    // refresh the cached dictionary
    self.substitutions = [self loadSubstitutionsFromDB];
}

- (void)removeSubstitution:(NSString *)key {
    if (!_subDbQueue)
        return;
    [_subDbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM substitutions WHERE key = ?", key];
    }];
    self.substitutions = [self loadSubstitutionsFromDB];
}

// Prefix lookup as a B-tree range instead of `LIKE 'prefix%'`.
//
// The LIKE form cannot use idx_word: SQLite's LIKE optimization requires the
// column to be indexed with the NOCASE collating sequence while the shipped
// index is BINARY, so every candidate refresh scanned all 140k rows
// (`SCAN words`, measured ~7.5ms, up to ~11ms for a one-character prefix).
// `word >= prefix AND word < prefix + U+10FFFF` is the same set of words and
// does use the index: ~70-400x faster for the three-or-more-character prefixes
// that dominate English typing. It also stops treating `_` and `%` typed by the
// user as LIKE wildcards.
//
// `prefix` is the lowercased user input and the dictionary is stored
// lowercased, so byte comparison returns what the case-insensitive LIKE did.
// The tie-break keeps equal-frequency words in a stable order, and LIMIT
// matches what the panel can display, which keeps the ORDER BY sorter bounded
// instead of sorting every match.
- (NSMutableArray *)wordsStartsWith:(NSString *)prefix {
    return [self wordsStartsWith:prefix limit:kMaxCandidates];
}

- (NSMutableArray *)wordsStartsWith:(NSString *)prefix limit:(NSUInteger)limit {
    if (!_dbQueue)
        return [[NSMutableArray alloc] init];
    NSString *lowerPrefix = [prefix lowercaseString];
    NSString *upperBound = [lowerPrefix stringByAppendingString:kPrefixUpperBound];
    __block NSMutableArray *filtered = [[NSMutableArray alloc] init];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT word FROM words WHERE word >= ? AND word < ? "
                         "ORDER BY frequency DESC, word ASC LIMIT ?";
        FMResultSet *resultSet = [db executeQuery:sql, lowerPrefix, upperBound, @(limit)];
        while ([resultSet next]) {
            [filtered addObject:[resultSet stringForColumn:@"word"]];
        }
    }];
    return filtered;
}

// The lowercase input when it qualifies for English rows (>=4 letters,
// letters only, not complete pinyin), else nil. Rime keeps the typed case
// (Hello), so callers lowercase before matching and clone the typed case back.
- (NSString *)lowercaseNonPinyinInput:(NSString *)input {
    NSString *lower = input.lowercaseString;
    if (lower.length < 4) {
        return nil;
    }
    for (NSUInteger i = 0; i < lower.length; i++) {
        unichar c = [lower characterAtIndex:i];
        if (c < 'a' || c > 'z') {
            return nil;
        }
    }
    return [PinyinSegmenter canFullySegment:lower] ? nil : lower;
}

- (NSArray<NSString *> *)englishCandidatesForNonPinyinInput:(NSString *)input {
    NSString *lower = [self lowercaseNonPinyinInput:input];
    if (!lower) {
        return @[];
    }
    // The typed word itself, when it is one, is offered first: without this,
    // a more frequent longer completion takes row 0 (her -> here, con ->
    // contact) and space commits a word the user never typed.
    NSMutableArray *words = [[NSMutableArray alloc] init];
    if ([self isDictionaryWord:lower]) {
        [words addObject:lower];
    }
    for (NSString *word in [self wordsStartsWith:lower limit:kEnglishCandidateLimit]) {
        if (![word isEqualToString:lower]) {
            [words addObject:word];
        }
    }
    return [self cloneTypedCase:input ontoWords:[self subarrayWithRang:words range:kEnglishCandidateLimit]];
}

- (BOOL)isDictionaryWord:(NSString *)word {
    if (!_dbQueue) {
        return NO;
    }
    __block BOOL found = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        found = [db boolForQuery:@"SELECT 1 FROM words WHERE word = ?", word];
    }];
    return found;
}

// Rime's abbreviations match almost any letters (conectivity included), so a
// guess cannot wait for Rime to come up empty; five letters is the cut
// instead. Most Chinese abbreviations are shorter (zme/dagn stay
// Chinese-first) but long shorthands and dropped-letter typos (shenm,
// weishenm) can still take English rows - a known trade-off.
- (NSArray<NSString *> *)spellingSuggestionsForNonPinyinInput:(NSString *)input {
    NSString *lower = [self lowercaseNonPinyinInput:input];
    if (lower.length < 5) {
        return @[];
    }
    return [self cloneTypedCase:input ontoWords:[self spellingSuggestionsForInput:lower]];
}

// Suffix-preserving case clone: the typed letters keep their case (Tes ->
// Test, Testing), the completion keeps the dictionary's.
- (NSArray<NSString *> *)cloneTypedCase:(NSString *)input ontoWords:(NSArray<NSString *> *)words {
    if ([input isEqualToString:input.lowercaseString]) {
        return words;
    }
    NSString *lower = input.lowercaseString;
    NSMutableArray *cased = [NSMutableArray array];
    for (NSString *word in words) {
        if ([word hasPrefix:lower]) {
            [cased addObject:[input stringByAppendingString:[word substringFromIndex:lower.length]]];
        } else {
            [cased addObject:word];
        }
    }
    return cased;
}

// Fallback for typo'd input: no word starts with the letters, so rank
// same-sounding dictionary words (conectivity -> connectivity) by edit
// distance ahead of the system spell checker's guesses.
- (NSArray<NSString *> *)spellingSuggestionsForInput:(NSString *)input {
    NSMutableArray *result = [NSMutableArray array];
    if (input.length > 3) {
        NSArray *bucket = (self.phonexEncoded)[[self phonexEncode:input]];
        for (NSString *word in [self sortByDamerauLevenshteinDistance:bucket inputText:input]) {
            if (![word isEqualToString:input]) {
                [result addObject:word];
            }
        }
    }
    if (result.count < kEnglishCandidateLimit) {
        NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
        NSArray *guesses = [checker guessesForWordRange:NSMakeRange(0, input.length)
                                               inString:input
                                               language:@"en"
                                 inSpellDocumentWithTag:0];
        for (NSString *guess in guesses) {
            if ([guess isEqualToString:input] || [result containsObject:guess]) {
                continue;
            }
            [result addObject:guess];
            if (result.count == kEnglishCandidateLimit) {
                break;
            }
        }
    }
    return [self subarrayWithRang:result range:kEnglishCandidateLimit];
}

- (NSString *)phonexEncode:(NSString *)word {
    if (!self.phonexEncoder) {
        return @"";
    }
    return [[self.phonexEncoder callWithArguments:@[ word ]] toString] ?: @"";
}

- (NSArray *)getTranslations:(NSString *)word {
    if (!_dbQueue)
        return @[];
    __block NSArray *translation = @[];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT translation FROM words WHERE word = ?";
        FMResultSet *resultSet = [db executeQuery:sql, word.lowercaseString];
        if ([resultSet next]) {
            NSString *transStr = [resultSet stringForColumn:@"translation"];
            if (transStr && transStr.length > 0) {
                translation = [transStr componentsSeparatedByString:@"|"];
            }
        }
    }];
    return translation;
}

- (NSString *)getPhoneticSymbolOfWord:(NSString *)candidateString {
    if (candidateString && candidateString.length > 3) {
        __block NSString *ipa = nil;
        NSString *word = candidateString.lowercaseString;
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"SELECT ipa FROM words WHERE word = ?";
            FMResultSet *resultSet = [db executeQuery:sql, word];
            if ([resultSet next]) {
                ipa = [resultSet stringForColumn:@"ipa"];
            }
        }];
        return ipa;
    }
    return nil;
}

- (NSString *)getAnnotation:(NSString *)word {
    NSString *input = word.lowercaseString;
    NSArray *translation = [self getTranslations:input];
    if (translation && translation.count > 0) {
        NSString *translationText;
        NSString *phoneticSymbol = [self getPhoneticSymbolOfWord:input];
        if (phoneticSymbol.length > 0) {
            NSArray *list = @[ [NSString stringWithFormat:@"[%@]", phoneticSymbol] ];
            translationText = [[list arrayByAddingObjectsFromArray:translation] componentsJoinedByString:@"\n"];
        } else {
            translationText = [translation componentsJoinedByString:@"\n"];
        }
        return translationText;
    } else {
        return @"";
    }
}

- (NSArray *)sortByDamerauLevenshteinDistance:(NSArray *)original inputText:(NSString *)text {
    NSMutableArray *mutableArray = [NSMutableArray new];
    for (NSString *word in original) {
        NSUInteger distance = [text mdc_levenshteinDistanceTo:word];
        if (distance <= 3) {
            [mutableArray addObject:@{@"w" : word, @"d" : @(distance)}];
        }
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"d" ascending:YES];
    NSArray *sorted = [mutableArray sortedArrayUsingDescriptors:@[ descriptor ]];
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *obj in sorted) {
        [result addObject:obj[@"w"]];
    }
    return [result copy];
}

- (NSArray *)getSuggestionOfSpellChecker:(NSString *)buffer {
    NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
    NSRange range = NSMakeRange(0, buffer.length);
    NSArray *result = [checker guessesForWordRange:range inString:buffer language:@"en" inSpellDocumentWithTag:0];

    if (buffer.length > 3) {
        NSArray *words = (self.phonexEncoded)[[self phonexEncode:buffer]];
        NSArray *wordsWithSimilarPhone = [self sortByDamerauLevenshteinDistance:words inputText:buffer];
        if (wordsWithSimilarPhone && wordsWithSimilarPhone.count > 0) {
            NSUInteger range = 4;
            NSMutableArray *finalResult = [NSMutableArray arrayWithArray:[self subarrayWithRang:result range:range]];
            [finalResult addObjectsFromArray:[self subarrayWithRang:wordsWithSimilarPhone range:range]];
            return finalResult;
        }
    }
    return result;
}

- (NSArray *)subarrayWithRang:(NSArray *)array range:(NSUInteger)range {
    NSUInteger count = array.count;
    NSUInteger limit = count >= range ? range : count;
    return [array subarrayWithRange:NSMakeRange(0, limit)];
}

// The pinyin -> Chinese/English candidates used when the typed input is not an
// English prefix. They live in the bundled database (dictionary/build-sqlite.py)
// rather than a parsed cedict.json: that JSON cost ~49 MB resident for 10 MB of
// text, because every one of its 690k strings was an Objective-C object. Here
// only the stored row's string is materialised, and the stored list is already
// capped at kMaxCandidates - the same cap getCandidates: applies afterwards -
// so nothing that could be displayed is dropped.
- (NSArray<NSString *> *)pinyinWordsForInput:(NSString *)pinyin {
    if (!_dbQueue || pinyin.length == 0) {
        return @[];
    }
    __block NSArray<NSString *> *words = @[];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:@"SELECT words FROM cedict_pinyin WHERE pinyin = ?", pinyin];
        if ([resultSet next]) {
            NSString *joined = [resultSet stringForColumn:@"words"];
            if (joined.length > 0) {
                words = [joined componentsSeparatedByString:@"\n"];
            }
        }
    }];
    return words;
}

- (NSArray *)getCandidates:(NSString *)originalInput {
    NSString *buffer = originalInput.lowercaseString;
    NSMutableArray *result = [[NSMutableArray alloc] init];

    if (buffer && buffer.length > 0) {
        if (self.substitutions && self.substitutions[buffer]) {
            [result addObject:self.substitutions[buffer]];
        }

        NSMutableArray *filtered = [self wordsStartsWith:buffer];
        if (filtered && filtered.count > 0) {
            [result addObjectsFromArray:filtered];
        } else {
            [result addObjectsFromArray:[self getSuggestionOfSpellChecker:buffer]];
        }

        [result addObjectsFromArray:[self pinyinWordsForInput:buffer]];

        // The typed input is moved to the front, then the whole list is capped,
        // so the cap has to be applied after the move: the prefix query already
        // returns at most kMaxCandidates words, and capping before the insert
        // would let the inserted input push the list one past the limit.
        [result removeObject:buffer];
        [result insertObject:buffer atIndex:0];
        if (result.count > kMaxCandidates) {
            result = [NSMutableArray arrayWithArray:[result subarrayWithRange:NSMakeRange(0, kMaxCandidates)]];
        }
    }

    NSMutableArray *result2 = [[NSMutableArray alloc] init];
    for (NSString *word in result) {
        if ([word hasPrefix:buffer]) {
            [result2 addObject:[NSString stringWithFormat:@"%@%@", originalInput, [word substringFromIndex:originalInput.length]]];
        } else {
            [result2 addObject:word];
        }
    }
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:result2];
    NSArray *arrayWithoutDuplicates = orderedSet.array;
    return [NSArray arrayWithArray:arrayWithoutDuplicates];
}

@end
