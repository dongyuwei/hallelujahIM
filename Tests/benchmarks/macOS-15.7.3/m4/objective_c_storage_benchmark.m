#define _DARWIN_C_SOURCE

#import "FMDB.h"
#import <Foundation/Foundation.h>

#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <lmdb.h>
#include <math.h>
#include <sqlite3.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <time.h>

#define DEFAULT_DATABASE "dictionary/words_with_frequency_and_translation_and_ipa.sqlite3"
#define LMDB_MAP_SIZE (256ULL * 1024ULL * 1024ULL)

static volatile uint64_t benchmarkSink;

@interface HLCandidate : NSObject

@property(nonatomic, copy) NSString *word;
@property(nonatomic) uint64_t frequency;

- (instancetype)initWithWord:(NSString *)word frequency:(uint64_t)frequency;

@end

@implementation HLCandidate

- (instancetype)initWithWord:(NSString *)word frequency:(uint64_t)frequency {
    self = [super init];
    if (self != nil) {
        _word = [word copy];
        _frequency = frequency;
    }
    return self;
}

@end

@interface HLWordInfo : NSObject

@property(nonatomic) uint64_t frequency;
@property(nonatomic, copy) NSString *translation;
@property(nonatomic, copy) NSString *ipa;

- (instancetype)initWithFrequency:(uint64_t)frequency translation:(NSString *)translation ipa:(NSString *)ipa;

@end

@implementation HLWordInfo

- (instancetype)initWithFrequency:(uint64_t)frequency translation:(NSString *)translation ipa:(NSString *)ipa {
    self = [super init];
    if (self != nil) {
        _frequency = frequency;
        _translation = [translation copy];
        _ipa = [ipa copy];
    }
    return self;
}

@end

typedef struct {
    MDB_env *environment;
    MDB_dbi database;
} HLLMDBQueries;

typedef struct {
    double *values;
    NSUInteger inputCount;
    NSUInteger iterations;
} HLSamples;

static void Fail(NSString *message) {
    fprintf(stderr, "error: %s\n", message.UTF8String);
    exit(EXIT_FAILURE);
}

static void FailErrno(NSString *context) { Fail([NSString stringWithFormat:@"%@: %s", context, strerror(errno)]); }

static void CheckSQLite(int result, sqlite3 *database, NSString *context) {
    if (result == SQLITE_OK || result == SQLITE_DONE || result == SQLITE_ROW) {
        return;
    }
    const char *message = database == NULL ? sqlite3_errstr(result) : sqlite3_errmsg(database);
    Fail([NSString stringWithFormat:@"%@: %s", context, message]);
}

static void ExecuteSQLite(sqlite3 *database, const char *sql) {
    char *message = NULL;
    int result = sqlite3_exec(database, sql, NULL, NULL, &message);
    if (result != SQLITE_OK) {
        NSString *description =
            [NSString stringWithFormat:@"SQLite statement failed: %s", message == NULL ? sqlite3_errmsg(database) : message];
        sqlite3_free(message);
        Fail(description);
    }
}

static void CheckLMDB(int result, NSString *context) {
    if (result != MDB_SUCCESS) {
        Fail([NSString stringWithFormat:@"%@: %s", context, mdb_strerror(result)]);
    }
}

static double MonotonicSeconds(void) {
    struct timespec time;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &time) != 0) {
        FailErrno(@"clock_gettime");
    }
    return (double)time.tv_sec + (double)time.tv_nsec / 1000000000.0;
}

static void WriteUInt64BigEndian(unsigned char *destination, uint64_t value) {
    for (size_t index = 0; index < 8; ++index) {
        destination[7 - index] = (unsigned char)(value & 0xff);
        value >>= 8;
    }
}

static void WriteUInt32BigEndian(unsigned char *destination, uint32_t value) {
    for (size_t index = 0; index < 4; ++index) {
        destination[3 - index] = (unsigned char)(value & 0xff);
        value >>= 8;
    }
}

static uint64_t ReadUInt64BigEndian(const unsigned char *source) {
    uint64_t value = 0;
    for (size_t index = 0; index < 8; ++index) {
        value = (value << 8) | source[index];
    }
    return value;
}

static uint32_t ReadUInt32BigEndian(const unsigned char *source) {
    uint32_t value = 0;
    for (size_t index = 0; index < 4; ++index) {
        value = (value << 8) | source[index];
    }
    return value;
}

static void PrepareStores(NSString *sourcePath, NSString **temporaryDirectory, NSString **sqlitePath, NSString **lmdbPath) {
    char directoryTemplate[] = "/tmp/hallelujah-objective-c-storage-XXXXXX";
    if (mkdtemp(directoryTemplate) == NULL) {
        FailErrno(@"create benchmark temporary directory");
    }
    *temporaryDirectory = [[NSString alloc] initWithUTF8String:directoryTemplate];
    *sqlitePath = [*temporaryDirectory stringByAppendingPathComponent:@"words.sqlite3"];
    *lmdbPath = [*temporaryDirectory stringByAppendingPathComponent:@"words.lmdb"];

    NSError *directoryError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:*lmdbPath
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&directoryError]) {
        Fail([NSString stringWithFormat:@"create LMDB directory: %@", directoryError.localizedDescription]);
    }

    sqlite3 *sourceDatabase = NULL;
    int openResult = sqlite3_open_v2(sourcePath.fileSystemRepresentation, &sourceDatabase, SQLITE_OPEN_READONLY, NULL);
    CheckSQLite(openResult, sourceDatabase, @"open source SQLite database");

    sqlite3 *targetDatabase = NULL;
    openResult = sqlite3_open((*sqlitePath).fileSystemRepresentation, &targetDatabase);
    CheckSQLite(openResult, targetDatabase, @"create SQLite benchmark database");
    ExecuteSQLite(targetDatabase, "CREATE TABLE words (word TEXT PRIMARY KEY, frequency INTEGER, "
                                  "translation TEXT, ipa TEXT)");
    ExecuteSQLite(targetDatabase, "BEGIN");

    sqlite3_stmt *sourceStatement = NULL;
    CheckSQLite(
        sqlite3_prepare_v2(sourceDatabase, "SELECT word, frequency, translation, ipa FROM words ORDER BY word", -1, &sourceStatement, NULL),
        sourceDatabase, @"prepare source word query");
    sqlite3_stmt *insertStatement = NULL;
    CheckSQLite(sqlite3_prepare_v2(targetDatabase,
                                   "INSERT INTO words (word, frequency, translation, ipa) VALUES "
                                   "(?, ?, ?, ?)",
                                   -1, &insertStatement, NULL),
                targetDatabase, @"prepare SQLite insert");

    MDB_env *environment = NULL;
    CheckLMDB(mdb_env_create(&environment), @"create LMDB build environment");
    CheckLMDB(mdb_env_set_mapsize(environment, LMDB_MAP_SIZE), @"set LMDB map size");
    CheckLMDB(mdb_env_open(environment, (*lmdbPath).fileSystemRepresentation, 0, 0644), @"open LMDB build environment");
    MDB_txn *transaction = NULL;
    MDB_dbi database;
    CheckLMDB(mdb_txn_begin(environment, NULL, 0, &transaction), @"begin LMDB build transaction");
    CheckLMDB(mdb_dbi_open(transaction, NULL, 0, &database), @"open LMDB build database");

    int stepResult;
    while ((stepResult = sqlite3_step(sourceStatement)) == SQLITE_ROW) {
        const unsigned char *word = sqlite3_column_text(sourceStatement, 0);
        int wordSize = sqlite3_column_bytes(sourceStatement, 0);
        uint64_t frequency = (uint64_t)sqlite3_column_int64(sourceStatement, 1);
        const unsigned char *translation = sqlite3_column_text(sourceStatement, 2);
        int translationSize = sqlite3_column_bytes(sourceStatement, 2);
        const unsigned char *ipa = sqlite3_column_text(sourceStatement, 3);
        int ipaSize = sqlite3_column_bytes(sourceStatement, 3);

        CheckSQLite(sqlite3_bind_text(insertStatement, 1, (const char *)word, wordSize, SQLITE_TRANSIENT), targetDatabase,
                    @"bind SQLite word");
        CheckSQLite(sqlite3_bind_int64(insertStatement, 2, (sqlite3_int64)frequency), targetDatabase, @"bind SQLite frequency");
        CheckSQLite(sqlite3_bind_text(insertStatement, 3, translation == NULL ? "" : (const char *)translation,
                                      translation == NULL ? 0 : translationSize, SQLITE_TRANSIENT),
                    targetDatabase, @"bind SQLite translation");
        CheckSQLite(
            sqlite3_bind_text(insertStatement, 4, ipa == NULL ? "" : (const char *)ipa, ipa == NULL ? 0 : ipaSize, SQLITE_TRANSIENT),
            targetDatabase, @"bind SQLite IPA");
        CheckSQLite(sqlite3_step(insertStatement), targetDatabase, @"insert SQLite word");
        CheckSQLite(sqlite3_reset(insertStatement), targetDatabase, @"reset SQLite insert");
        CheckSQLite(sqlite3_clear_bindings(insertStatement), targetDatabase, @"clear SQLite insert bindings");

        if ((uint64_t)translationSize > UINT32_MAX) {
            Fail(@"translation is too large for LMDB encoding");
        }
        size_t valueSize = 12 + (size_t)translationSize + (size_t)ipaSize;
        unsigned char *valueBytes = malloc(valueSize);
        if (valueBytes == NULL) {
            Fail(@"out of memory");
        }
        WriteUInt64BigEndian(valueBytes, frequency);
        WriteUInt32BigEndian(valueBytes + 8, (uint32_t)translationSize);
        if (translationSize > 0) {
            memcpy(valueBytes + 12, translation, (size_t)translationSize);
        }
        if (ipaSize > 0) {
            memcpy(valueBytes + 12 + translationSize, ipa, (size_t)ipaSize);
        }
        MDB_val key = {.mv_size = (size_t)wordSize, .mv_data = (void *)word};
        MDB_val value = {.mv_size = valueSize, .mv_data = valueBytes};
        int putResult = mdb_put(transaction, database, &key, &value, MDB_APPEND);
        free(valueBytes);
        CheckLMDB(putResult, @"append LMDB word");
    }
    if (stepResult != SQLITE_DONE) {
        CheckSQLite(stepResult, sourceDatabase, @"read source words");
    }

    CheckSQLite(sqlite3_finalize(sourceStatement), sourceDatabase, @"finalize source query");
    CheckSQLite(sqlite3_finalize(insertStatement), targetDatabase, @"finalize SQLite insert");
    ExecuteSQLite(targetDatabase, "COMMIT");
    ExecuteSQLite(targetDatabase, "CREATE INDEX idx_word ON words(word)");
    CheckSQLite(sqlite3_close(sourceDatabase), sourceDatabase, @"close source SQLite database");
    CheckSQLite(sqlite3_close(targetDatabase), targetDatabase, @"close target SQLite database");
    CheckLMDB(mdb_txn_commit(transaction), @"commit LMDB build transaction");
    CheckLMDB(mdb_env_sync(environment, 1), @"sync LMDB build environment");
    mdb_dbi_close(environment, database);
    mdb_env_close(environment);
}

static NSString *PrefixUpperBound(NSString *prefix) {
    NSData *data = [prefix dataUsingEncoding:NSASCIIStringEncoding];
    if (data == nil || data.length == 0) {
        Fail(@"prefix must contain ASCII text");
    }
    NSMutableData *upperData = [data mutableCopy];
    unsigned char *bytes = upperData.mutableBytes;
    for (NSUInteger index = upperData.length; index > 0; --index) {
        if (bytes[index - 1] < 0x7f) {
            bytes[index - 1] += 1;
            [upperData setLength:index];
            NSString *upper = [[NSString alloc] initWithData:upperData encoding:NSASCIIStringEncoding];
            if (upper == nil) {
                Fail(@"could not construct prefix upper bound");
            }
            return upper;
        }
    }
    Fail(@"prefix must contain an ASCII byte below 0x7f");
    return @"";
}

static NSArray<NSString *> *SQLitePrefix(FMDatabaseQueue *queue, NSString *prefix, BOOL useRange) {
    __block NSMutableArray<NSString *> *results = [NSMutableArray array];
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *resultSet;
        if (useRange) {
            resultSet = [database executeQuery:@"SELECT word FROM words WHERE word >= ? AND "
                                                "word < ? ORDER BY frequency DESC, word ASC",
                                               prefix, PrefixUpperBound(prefix)];
        } else {
            resultSet = [database executeQuery:@"SELECT word FROM words WHERE word LIKE ? "
                                                "ORDER BY frequency DESC, word ASC",
                                               [prefix stringByAppendingString:@"%"]];
        }
        if (resultSet == nil) {
            Fail([NSString stringWithFormat:@"SQLite prefix query failed: %@", database.lastErrorMessage]);
        }
        while ([resultSet next]) {
            NSString *word = [resultSet stringForColumnIndex:0] ?: @"";
            [results addObject:word];
        }
        [resultSet close];
    }];
    return [results copy];
}

static HLLMDBQueries OpenLMDBQueries(NSString *databasePath) {
    HLLMDBQueries queries = {0};
    CheckLMDB(mdb_env_create(&queries.environment), @"create LMDB read environment");
    CheckLMDB(mdb_env_open(queries.environment, databasePath.fileSystemRepresentation, MDB_RDONLY | MDB_NOTLS | MDB_NOLOCK, 0444),
              @"open LMDB read environment");
    MDB_txn *transaction = NULL;
    CheckLMDB(mdb_txn_begin(queries.environment, NULL, MDB_RDONLY, &transaction), @"begin LMDB setup transaction");
    CheckLMDB(mdb_dbi_open(transaction, NULL, 0, &queries.database), @"open LMDB read database");
    mdb_txn_abort(transaction);
    return queries;
}

static NSArray<NSString *> *LMDBPrefix(const HLLMDBQueries *queries, NSString *prefix) {
    NSData *prefixData = [prefix dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray<HLCandidate *> *results = [NSMutableArray array];
    MDB_txn *transaction = NULL;
    MDB_cursor *cursor = NULL;
    CheckLMDB(mdb_txn_begin(queries->environment, NULL, MDB_RDONLY, &transaction), @"begin LMDB prefix transaction");
    CheckLMDB(mdb_cursor_open(transaction, queries->database, &cursor), @"open LMDB prefix cursor");

    MDB_val key = {.mv_size = prefixData.length, .mv_data = (void *)prefixData.bytes};
    MDB_val value;
    int result = mdb_cursor_get(cursor, &key, &value, MDB_SET_RANGE);
    while (result == MDB_SUCCESS) {
        if (key.mv_size < prefixData.length || memcmp(key.mv_data, prefixData.bytes, prefixData.length) != 0) {
            break;
        }
        if (value.mv_size < 12) {
            Fail(@"invalid LMDB prefix value");
        }
        NSString *word = [[NSString alloc] initWithBytes:key.mv_data length:key.mv_size encoding:NSUTF8StringEncoding];
        if (word == nil) {
            Fail(@"invalid UTF-8 LMDB key");
        }
        uint64_t frequency = ReadUInt64BigEndian(value.mv_data);
        [results addObject:[[HLCandidate alloc] initWithWord:word frequency:frequency]];
        result = mdb_cursor_get(cursor, &key, &value, MDB_NEXT);
    }
    if (result != MDB_SUCCESS && result != MDB_NOTFOUND) {
        CheckLMDB(result, @"iterate LMDB prefix cursor");
    }
    mdb_cursor_close(cursor);
    mdb_txn_abort(transaction);

    [results sortUsingComparator:^NSComparisonResult(HLCandidate *left, HLCandidate *right) {
        if (left.frequency > right.frequency) {
            return NSOrderedAscending;
        }
        if (left.frequency < right.frequency) {
            return NSOrderedDescending;
        }
        return [left.word compare:right.word];
    }];
    NSMutableArray<NSString *> *words = [NSMutableArray arrayWithCapacity:results.count];
    for (HLCandidate *candidate in results) {
        [words addObject:candidate.word];
    }
    return [words copy];
}

static HLWordInfo *SQLiteExact(FMDatabaseQueue *queue, NSString *word) {
    __block HLWordInfo *information = nil;
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *resultSet = [database executeQuery:@"SELECT frequency, translation, ipa FROM words WHERE word = ?", word];
        if (resultSet == nil) {
            Fail([NSString stringWithFormat:@"SQLite exact query failed: %@", database.lastErrorMessage]);
        }
        if ([resultSet next]) {
            information = [[HLWordInfo alloc] initWithFrequency:[resultSet unsignedLongLongIntForColumnIndex:0]
                                                    translation:[resultSet stringForColumnIndex:1] ?: @""
                                                            ipa:[resultSet stringForColumnIndex:2] ?: @""];
        }
        [resultSet close];
    }];
    return information;
}

static HLWordInfo *LMDBExact(const HLLMDBQueries *queries, NSString *word) {
    NSData *wordData = [word dataUsingEncoding:NSUTF8StringEncoding];
    MDB_txn *transaction = NULL;
    CheckLMDB(mdb_txn_begin(queries->environment, NULL, MDB_RDONLY, &transaction), @"begin LMDB exact transaction");
    MDB_val key = {.mv_size = wordData.length, .mv_data = (void *)wordData.bytes};
    MDB_val value;
    int result = mdb_get(transaction, queries->database, &key, &value);
    HLWordInfo *information = nil;
    if (result == MDB_SUCCESS) {
        if (value.mv_size < 12) {
            Fail(@"invalid LMDB exact value");
        }
        const unsigned char *bytes = value.mv_data;
        uint32_t translationSize = ReadUInt32BigEndian(bytes + 8);
        if ((size_t)translationSize > value.mv_size - 12) {
            Fail(@"invalid LMDB translation length");
        }
        NSString *translation = [[NSString alloc] initWithBytes:bytes + 12 length:translationSize encoding:NSUTF8StringEncoding];
        NSString *ipa = [[NSString alloc] initWithBytes:bytes + 12 + translationSize
                                                 length:value.mv_size - 12 - translationSize
                                               encoding:NSUTF8StringEncoding];
        if (translation == nil || ipa == nil) {
            Fail(@"invalid UTF-8 LMDB value");
        }
        information = [[HLWordInfo alloc] initWithFrequency:ReadUInt64BigEndian(bytes) translation:translation ipa:ipa];
    } else if (result != MDB_NOTFOUND) {
        CheckLMDB(result, @"execute LMDB exact query");
    }
    mdb_txn_abort(transaction);
    return information;
}

static void ValidatePrefixResults(NSArray<NSString *> *left, NSArray<NSString *> *right, NSString *prefix) {
    if (left.count != right.count) {
        Fail([NSString stringWithFormat:@"result counts differ for prefix %@", prefix]);
    }
    for (NSUInteger index = 0; index < left.count; ++index) {
        if (![left[index] isEqualToString:right[index]]) {
            Fail([NSString stringWithFormat:@"results differ for prefix %@", prefix]);
        }
    }
}

static void ValidateExactResults(HLWordInfo *left, HLWordInfo *right, NSString *word) {
    if ((left == nil) != (right == nil)) {
        Fail([NSString stringWithFormat:@"exact results differ for word %@", word]);
    }
    if (left != nil && (left.frequency != right.frequency || ![left.translation isEqualToString:right.translation] ||
                        ![left.ipa isEqualToString:right.ipa])) {
        Fail([NSString stringWithFormat:@"exact results differ for word %@", word]);
    }
}

static HLSamples MeasurePrefix(NSArray<NSString *> *inputs, NSUInteger iterations, NSUInteger warmup,
                               NSArray<NSString *> * (^operation)(NSString *)) {
    for (NSUInteger iteration = 0; iteration < warmup; ++iteration) {
        for (NSString *input in inputs) {
            @autoreleasepool {
                benchmarkSink += operation(input).count;
            }
        }
    }

    HLSamples samples = {
        .values = calloc(inputs.count * iterations, sizeof(double)),
        .inputCount = inputs.count,
        .iterations = iterations,
    };
    if (samples.values == NULL) {
        Fail(@"out of memory");
    }
    for (NSUInteger iteration = 0; iteration < iterations; ++iteration) {
        for (NSUInteger input = 0; input < inputs.count; ++input) {
            double started = MonotonicSeconds();
            @autoreleasepool {
                benchmarkSink += operation(inputs[input]).count;
            }
            samples.values[input * iterations + iteration] = (MonotonicSeconds() - started) * 1000.0;
        }
    }
    return samples;
}

static HLSamples MeasureExact(NSArray<NSString *> *inputs, NSUInteger iterations, NSUInteger warmup,
                              HLWordInfo * (^operation)(NSString *)) {
    for (NSUInteger iteration = 0; iteration < warmup; ++iteration) {
        for (NSString *input in inputs) {
            @autoreleasepool {
                HLWordInfo *information = operation(input);
                benchmarkSink += information == nil ? 1 : information.frequency;
            }
        }
    }

    HLSamples samples = {
        .values = calloc(inputs.count * iterations, sizeof(double)),
        .inputCount = inputs.count,
        .iterations = iterations,
    };
    if (samples.values == NULL) {
        Fail(@"out of memory");
    }
    for (NSUInteger iteration = 0; iteration < iterations; ++iteration) {
        for (NSUInteger input = 0; input < inputs.count; ++input) {
            double started = MonotonicSeconds();
            @autoreleasepool {
                HLWordInfo *information = operation(inputs[input]);
                benchmarkSink += information == nil ? 1 : information.frequency;
            }
            samples.values[input * iterations + iteration] = (MonotonicSeconds() - started) * 1000.0;
        }
    }
    return samples;
}

static int CompareDoubles(const void *left, const void *right) {
    double leftValue = *(const double *)left;
    double rightValue = *(const double *)right;
    return (leftValue > rightValue) - (leftValue < rightValue);
}

static double Percentile(const double *values, NSUInteger count, double percentage) {
    double *ordered = malloc(count * sizeof(double));
    if (ordered == NULL) {
        Fail(@"out of memory");
    }
    memcpy(ordered, values, count * sizeof(double));
    qsort(ordered, count, sizeof(double), CompareDoubles);
    NSUInteger index = (NSUInteger)ceil((double)count * percentage);
    index = index == 0 ? 0 : index - 1;
    double result = ordered[index];
    free(ordered);
    return result;
}

static double Median(const double *values, NSUInteger count) {
    double *ordered = malloc(count * sizeof(double));
    if (ordered == NULL) {
        Fail(@"out of memory");
    }
    memcpy(ordered, values, count * sizeof(double));
    qsort(ordered, count, sizeof(double), CompareDoubles);
    double result = count % 2 == 0 ? (ordered[count / 2 - 1] + ordered[count / 2]) / 2.0 : ordered[count / 2];
    free(ordered);
    return result;
}

static void PrintMeasurement(NSString *name, HLSamples *samples) {
    NSUInteger count = samples->inputCount * samples->iterations;
    printf("| %s | %.4f | %.4f |\n", name.UTF8String, Median(samples->values, count), Percentile(samples->values, count, 0.95));
}

static NSUInteger ParseCount(const char *value, NSString *option) {
    char *end = NULL;
    errno = 0;
    unsigned long parsed = strtoul(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' || parsed > NSUIntegerMax) {
        Fail([NSString stringWithFormat:@"invalid value for %@: %s", option, value]);
    }
    return (NSUInteger)parsed;
}

static void PrintUsage(const char *program) { printf("Usage: %s [--database PATH] [--iterations N] [--warmup N]\n", program); }

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *sourcePath = @DEFAULT_DATABASE;
        NSUInteger iterations = 100;
        NSUInteger warmup = 10;
        for (int index = 1; index < argc; ++index) {
            if (strcmp(argv[index], "--database") == 0 && index + 1 < argc) {
                sourcePath = [[NSString alloc] initWithUTF8String:argv[++index]];
            } else if (strcmp(argv[index], "--iterations") == 0 && index + 1 < argc) {
                iterations = ParseCount(argv[++index], @"--iterations");
            } else if (strcmp(argv[index], "--warmup") == 0 && index + 1 < argc) {
                warmup = ParseCount(argv[++index], @"--warmup");
            } else if (strcmp(argv[index], "--help") == 0) {
                PrintUsage(argv[0]);
                return EXIT_SUCCESS;
            } else {
                PrintUsage(argv[0]);
                return EXIT_FAILURE;
            }
        }
        if (iterations == 0) {
            Fail(@"iterations must be positive");
        }

        NSString *temporaryDirectory;
        NSString *sqlitePath;
        NSString *lmdbPath;
        PrepareStores(sourcePath, &temporaryDirectory, &sqlitePath, &lmdbPath);

        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:sqlitePath];
        if (queue == nil) {
            Fail(@"could not create FMDB queue");
        }
        [queue inDatabase:^(FMDatabase *database) {
            database.shouldCacheStatements = YES;
        }];
        HLLMDBQueries lmdbQueries = OpenLMDBQueries(lmdbPath);

        NSArray<NSString *> *prefixes = @[ @"a", @"th", @"tes", @"apple", @"psych", @"z", @"xyl", @"algorithm", @"notaword" ];
        NSArray<NSString *> *exactWords =
            @[ @"the", @"test", @"algorithm", @"hallelujah", @"psychology", @"xylophone", @"zyzzyva", @"not-in-the-dictionary" ];

        for (NSString *prefix in prefixes) {
            NSArray<NSString *> *like = SQLitePrefix(queue, prefix, NO);
            NSArray<NSString *> *range = SQLitePrefix(queue, prefix, YES);
            NSArray<NSString *> *lmdb = LMDBPrefix(&lmdbQueries, prefix);
            ValidatePrefixResults(like, range, prefix);
            ValidatePrefixResults(range, lmdb, prefix);
        }
        for (NSString *word in exactWords) {
            ValidateExactResults(SQLiteExact(queue, word), LMDBExact(&lmdbQueries, word), word);
        }

        HLSamples likeSamples = MeasurePrefix(prefixes, iterations, warmup, ^NSArray<NSString *> *(NSString *prefix) {
            return SQLitePrefix(queue, prefix, NO);
        });
        HLSamples rangeSamples = MeasurePrefix(prefixes, iterations, warmup, ^NSArray<NSString *> *(NSString *prefix) {
            return SQLitePrefix(queue, prefix, YES);
        });
        HLSamples lmdbPrefixSamples = MeasurePrefix(prefixes, iterations, warmup, ^NSArray<NSString *> *(NSString *prefix) {
            return LMDBPrefix(&lmdbQueries, prefix);
        });
        HLSamples sqliteExactSamples = MeasureExact(exactWords, iterations, warmup, ^HLWordInfo *(NSString *word) {
            return SQLiteExact(queue, word);
        });
        HLSamples lmdbExactSamples = MeasureExact(exactWords, iterations, warmup, ^HLWordInfo *(NSString *word) {
            return LMDBExact(&lmdbQueries, word);
        });

        struct utsname systemInformation;
        if (uname(&systemInformation) != 0) {
            FailErrno(@"read system information");
        }
        char cpuName[256] = "unknown";
        size_t cpuNameSize = sizeof(cpuName);
        if (sysctlbyname("machdep.cpu.brand_string", cpuName, &cpuNameSize, NULL, 0) != 0) {
            snprintf(cpuName, sizeof(cpuName), "%s", systemInformation.machine);
        }
        int lmdbMajor;
        int lmdbMinor;
        int lmdbPatch;
        mdb_version(&lmdbMajor, &lmdbMinor, &lmdbPatch);

        printf("# Hallelujah Objective-C SQLite vs LMDB benchmark\n\n");
        printf("- Platform: %s %s (%s)\n", systemInformation.sysname, systemInformation.release, systemInformation.machine);
        printf("- CPU: %s\n", cpuName);
        printf("- SQLite: %s through FMDB 2.7.12\n", sqlite3_libversion());
        printf("- LMDB: %d.%d.%d\n", lmdbMajor, lmdbMinor, lmdbPatch);
        printf("- Iterations per input: %lu\n", (unsigned long)iterations);
        printf("- Result model: final NSArray<NSString *> with autorelease-pool cleanup\n\n");

        printf("## Warm query latency\n\n");
        printf("| Operation | p50 (ms) | p95 (ms) |\n");
        printf("| --- | ---: | ---: |\n");
        PrintMeasurement(@"FMDB SQLite prefix (`LIKE`, current)", &likeSamples);
        PrintMeasurement(@"FMDB SQLite prefix (indexed range)", &rangeSamples);
        PrintMeasurement(@"LMDB prefix cursor", &lmdbPrefixSamples);
        PrintMeasurement(@"FMDB SQLite exact lookup", &sqliteExactSamples);
        PrintMeasurement(@"LMDB exact lookup", &lmdbExactSamples);

        printf("\n## Prefix detail (median latency)\n\n");
        printf("| Prefix | Matches | FMDB `LIKE` (ms) | FMDB range (ms) | LMDB "
               "(ms) |\n");
        printf("| --- | ---: | ---: | ---: | ---: |\n");
        for (NSUInteger index = 0; index < prefixes.count; ++index) {
            NSUInteger count = SQLitePrefix(queue, prefixes[index], YES).count;
            printf("| `%s` | %lu | %.4f | %.4f | %.4f |\n", prefixes[index].UTF8String, (unsigned long)count,
                   Median(&likeSamples.values[index * iterations], iterations),
                   Median(&rangeSamples.values[index * iterations], iterations),
                   Median(&lmdbPrefixSamples.values[index * iterations], iterations));
        }

        free(likeSamples.values);
        free(rangeSamples.values);
        free(lmdbPrefixSamples.values);
        free(sqliteExactSamples.values);
        free(lmdbExactSamples.values);
        [queue close];
        mdb_dbi_close(lmdbQueries.environment, lmdbQueries.database);
        mdb_env_close(lmdbQueries.environment);

        NSError *cleanupError = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:&cleanupError]) {
            Fail([NSString stringWithFormat:@"remove benchmark files: %@", cleanupError.localizedDescription]);
        }
    }
    return benchmarkSink == UINT64_MAX ? EXIT_FAILURE : EXIT_SUCCESS;
}
