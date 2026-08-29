#import "ConversionEngine.h"

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

- (void)loadPreparedData {
    [self initDatabase];
    [self initSubstitutionDatabase];
    self.substitutions = [self loadSubstitutionsFromDB];
    self.pinyinDict = [self getPinyinData];
    self.phonexEncoded = [self getPhonexEncodedWords];
    self.phonexEncoder = [self getPhonexEncoder];
}

- (void)initDatabase {
    NSString *supportDir = [NSString stringWithFormat:@"%@/Library/Application Support/hallelujah", NSHomeDirectory()];
    NSString *dbPath = [supportDir stringByAppendingPathComponent:@"words_with_frequency_and_translation_and_ipa.sqlite3"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation_and_ipa" ofType:@"sqlite3"];
        if (!sourcePath) {
            sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"words_with_frequency_and_translation_and_ipa"
                                                                          ofType:@"sqlite3"];
        }
        if (!sourcePath) {
            NSLog(@"[Hallelujah] ERROR: words_with_frequency_and_translation_and_ipa.sqlite3 not found");
            return;
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:supportDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:dbPath error:&error];
        if (error) {
            NSLog(@"[Hallelujah] ERROR: Failed to copy database: %@", error.localizedDescription);
            return;
        }
        NSLog(@"[Hallelujah] Copied database to user directory: %@", dbPath);
    }

    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    if (!_dbQueue) {
        NSLog(@"[Hallelujah] ERROR: Failed to open database at %@", dbPath);
    }
}

- (NSDictionary *)getPinyinData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cedict" ofType:@"json"];
    return deserializeJSON(path);
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

- (NSMutableArray *)wordsStartsWith:(NSString *)prefix {
    if (!_dbQueue)
        return [[NSMutableArray alloc] init];
    __block NSMutableArray *filtered = [[NSMutableArray alloc] init];
    NSString *lowerPrefix = [prefix lowercaseString];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT word FROM words WHERE word LIKE ? ORDER BY frequency DESC";
        NSString *pattern = [NSString stringWithFormat:@"%@%%", lowerPrefix];
        FMResultSet *resultSet = [db executeQuery:sql, pattern];
        while ([resultSet next]) {
            [filtered addObject:[resultSet stringForColumn:@"word"]];
        }
    }];
    return filtered;
}

- (NSArray *)sortWordsByFrequency:(NSArray *)filtered {
    if (filtered.count == 0)
        return filtered;
    if (!_dbQueue)
        return filtered;

    NSMutableArray *placeholders = [NSMutableArray array];
    for (NSUInteger i = 0; i < filtered.count; i++) {
        [placeholders addObject:@"?"];
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT word FROM words WHERE word IN (%@) ORDER BY frequency DESC",
                                               [placeholders componentsJoinedByString:@","]];

    __block NSArray *sorted;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sql withArgumentsInArray:filtered];
        NSMutableArray *result = [NSMutableArray array];
        while ([resultSet next]) {
            [result addObject:[resultSet stringForColumn:@"word"]];
        }
        sorted = [result copy];
    }];
    return sorted;
}

- (NSString *)phonexEncode:(NSString *)word {
    return [[self.phonexEncoder callWithArguments:@[ word ]] toString];
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

- (NSArray *)predictNextWordsForContext:(NSString *)context maxResults:(NSInteger)max {
    return [self predictNextWordsForContext:context prefixFilter:nil maxResults:max];
}

- (NSArray *)predictNextWordsForContext:(NSString *)context prefixFilter:(NSString *)prefix maxResults:(NSInteger)max {
    if (!_dbQueue || !context || context.length == 0)
        return @[];

    NSString *lowerContext = context.lowercaseString;
    NSArray *contextWords = [lowerContext componentsSeparatedByString:@" "];

    // Remove empty strings from context
    NSMutableArray *cleanWords = [NSMutableArray array];
    for (NSString *w in contextWords) {
        if (w.length > 0)
            [cleanWords addObject:w];
    }
    if (cleanWords.count == 0)
        return @[];

    // Use at most the last 4 words as context (for 5-gram lookup)
    NSUInteger maxContextWords = 4;
    NSUInteger startIdx = cleanWords.count > maxContextWords ? cleanWords.count - maxContextWords : 0;
    NSArray *recentWords = [cleanWords subarrayWithRange:NSMakeRange(startIdx, cleanWords.count - startIdx)];

    __block NSMutableArray *results = [NSMutableArray array];

    [_dbQueue inDatabase:^(FMDatabase *db) {
        // Try from longest to shortest n-gram match
        // n = contextWords.count + 1, down to 2
        for (NSInteger n = recentWords.count + 1; n >= 2 && results.count < max; n--) {
            // Build the context for this n-gram level
            // For n=5 with 4 context words: use all 4 words
            // For n=4 with 4 context words: use last 3 words
            // For n=3 with 4 context words: use last 2 words
            // For n=2 with 4 context words: use last 1 word
            NSUInteger ctxLen = n - 1;
            if (ctxLen > recentWords.count)
                continue;

            NSArray *ctxWords = [recentWords subarrayWithRange:NSMakeRange(recentWords.count - ctxLen, ctxLen)];
            NSString *ctx = [ctxWords componentsJoinedByString:@" "];

            NSString *sql;
            FMResultSet *rs;

            if (prefix && prefix.length > 0) {
                NSString *lowerPrefix = prefix.lowercaseString;
                sql = @"SELECT next_word, frequency FROM ngrams WHERE n = ? AND context = ? AND next_word LIKE ? ORDER BY frequency DESC "
                      @"LIMIT ?";
                NSString *pattern = [NSString stringWithFormat:@"%@%%", lowerPrefix];
                rs = [db executeQuery:sql, @(n), ctx, pattern, @(max - results.count)];
            } else {
                sql = @"SELECT next_word, frequency FROM ngrams WHERE n = ? AND context = ? ORDER BY frequency DESC LIMIT ?";
                rs = [db executeQuery:sql, @(n), ctx, @(max - results.count)];
            }

            while ([rs next]) {
                NSString *word = [rs stringForColumn:@"next_word"];
                if (![results containsObject:word]) {
                    [results addObject:word];
                }
            }
            [rs close];
        }
    }];

    return [results copy];
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

        if (self.pinyinDict && self.pinyinDict[buffer]) {
            [result addObjectsFromArray:self.pinyinDict[buffer]];
        }

        if (result.count > 50) {
            result = [NSMutableArray arrayWithArray:[result subarrayWithRange:NSMakeRange(0, 49)]];
        }
        [result removeObject:buffer];
        [result insertObject:buffer atIndex:0];
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
