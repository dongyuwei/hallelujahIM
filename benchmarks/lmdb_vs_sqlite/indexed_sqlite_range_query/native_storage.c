#define _DARWIN_C_SOURCE

#include <dirent.h>
#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <lmdb.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#include <sqlite3.h>

#define DEFAULT_DATABASE "dictionary/words_with_frequency_and_translation_and_ipa.sqlite3"
#define LMDB_MAP_SIZE (256ULL * 1024ULL * 1024ULL)

static const char *DEFAULT_PREFIXES[] = {
    "a", "th", "tes", "apple", "psych", "z", "xyl", "algorithm", "notaword",
};

static const char *DEFAULT_EXACT_WORDS[] = {
    "the", "test", "algorithm", "hallelujah", "psychology", "xylophone", "zyzzyva", "not-in-the-dictionary",
};

static volatile uint64_t benchmark_sink;

typedef struct {
    char *word;
    uint64_t frequency;
    char *translation;
    char *ipa;
} WordRow;

typedef struct {
    WordRow *items;
    size_t count;
} WordRows;

typedef struct {
    char *word;
    uint64_t frequency;
} PrefixResult;

typedef struct {
    PrefixResult *items;
    size_t count;
    size_t capacity;
} PrefixResults;

typedef struct {
    bool found;
    uint64_t frequency;
    char *translation;
    char *ipa;
} ExactResult;

typedef struct {
    sqlite3 *database;
    sqlite3_stmt *like_statement;
    sqlite3_stmt *range_statement;
    sqlite3_stmt *exact_statement;
} SQLiteQueries;

typedef struct {
    MDB_env *environment;
    MDB_dbi database;
} LMDBQueries;

typedef struct {
    double *values;
    size_t input_count;
    size_t iterations;
} Samples;

typedef struct {
    uint64_t logical;
    uint64_t allocated;
} FileSize;

typedef void (*MeasuredOperation)(void *context, const char *input);

static void fail(const char *message) {
    fprintf(stderr, "error: %s\n", message);
    exit(EXIT_FAILURE);
}

static void fail_errno(const char *context) {
    fprintf(stderr, "error: %s: %s\n", context, strerror(errno));
    exit(EXIT_FAILURE);
}

static void check_sqlite(int result, sqlite3 *database, const char *context) {
    if (result == SQLITE_OK || result == SQLITE_DONE || result == SQLITE_ROW) {
        return;
    }
    fprintf(stderr, "error: %s: %s\n", context, database == NULL ? sqlite3_errstr(result) : sqlite3_errmsg(database));
    exit(EXIT_FAILURE);
}

static void check_lmdb(int result, const char *context) {
    if (result == MDB_SUCCESS) {
        return;
    }
    fprintf(stderr, "error: %s: %s\n", context, mdb_strerror(result));
    exit(EXIT_FAILURE);
}

static void *checked_malloc(size_t size) {
    void *pointer = malloc(size == 0 ? 1 : size);
    if (pointer == NULL) {
        fail("out of memory");
    }
    return pointer;
}

static void *checked_realloc(void *pointer, size_t size) {
    void *result = realloc(pointer, size == 0 ? 1 : size);
    if (result == NULL) {
        fail("out of memory");
    }
    return result;
}

static char *copy_bytes(const void *bytes, size_t length) {
    char *copy = checked_malloc(length + 1);
    if (length > 0) {
        memcpy(copy, bytes, length);
    }
    copy[length] = '\0';
    return copy;
}

static char *copy_sqlite_text(sqlite3_stmt *statement, int column) {
    const unsigned char *text = sqlite3_column_text(statement, column);
    int length = sqlite3_column_bytes(statement, column);
    if (text == NULL) {
        return copy_bytes("", 0);
    }
    return copy_bytes(text, (size_t)length);
}

static double monotonic_seconds(void) {
    struct timespec time;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &time) != 0) {
        fail_errno("clock_gettime");
    }
    return (double)time.tv_sec + (double)time.tv_nsec / 1000000000.0;
}

static void execute_sql(sqlite3 *database, const char *sql) {
    char *error_message = NULL;
    int result = sqlite3_exec(database, sql, NULL, NULL, &error_message);
    if (result != SQLITE_OK) {
        fprintf(stderr, "error: SQLite statement failed: %s\n", error_message == NULL ? sqlite3_errmsg(database) : error_message);
        sqlite3_free(error_message);
        exit(EXIT_FAILURE);
    }
}

static WordRows load_rows(const char *database_path, size_t *ngram_count) {
    sqlite3 *database = NULL;
    int open_result = sqlite3_open_v2(database_path, &database, SQLITE_OPEN_READONLY, NULL);
    check_sqlite(open_result, database, "open source SQLite database");

    sqlite3_stmt *statement = NULL;
    check_sqlite(sqlite3_prepare_v2(database, "SELECT word, frequency, translation, ipa FROM words ORDER BY word", -1, &statement, NULL),
                 database, "prepare source word query");

    WordRows rows = {0};
    size_t capacity = 0;
    int result;
    while ((result = sqlite3_step(statement)) == SQLITE_ROW) {
        if (rows.count == capacity) {
            capacity = capacity == 0 ? 4096 : capacity * 2;
            rows.items = checked_realloc(rows.items, capacity * sizeof(*rows.items));
        }
        WordRow *row = &rows.items[rows.count++];
        row->word = copy_sqlite_text(statement, 0);
        row->frequency = (uint64_t)sqlite3_column_int64(statement, 1);
        row->translation = copy_sqlite_text(statement, 2);
        row->ipa = copy_sqlite_text(statement, 3);
    }
    if (result != SQLITE_DONE) {
        check_sqlite(result, database, "read source words");
    }
    check_sqlite(sqlite3_finalize(statement), database, "finalize source word query");

    *ngram_count = 0;
    check_sqlite(sqlite3_prepare_v2(database,
                                    "SELECT count(*) FROM sqlite_master WHERE type = 'table' AND "
                                    "name = 'ngrams'",
                                    -1, &statement, NULL),
                 database, "prepare n-gram table query");
    if (sqlite3_step(statement) == SQLITE_ROW && sqlite3_column_int(statement, 0) > 0) {
        check_sqlite(sqlite3_finalize(statement), database, "finalize n-gram table query");
        statement = NULL;
        check_sqlite(sqlite3_prepare_v2(database, "SELECT count(*) FROM ngrams", -1, &statement, NULL), database,
                     "prepare n-gram count query");
        if (sqlite3_step(statement) == SQLITE_ROW) {
            *ngram_count = (size_t)sqlite3_column_int64(statement, 0);
        }
    }
    check_sqlite(sqlite3_finalize(statement), database, "finalize n-gram query");
    check_sqlite(sqlite3_close(database), database, "close source SQLite database");
    return rows;
}

static void free_rows(WordRows *rows) {
    for (size_t index = 0; index < rows->count; ++index) {
        free(rows->items[index].word);
        free(rows->items[index].translation);
        free(rows->items[index].ipa);
    }
    free(rows->items);
    *rows = (WordRows){0};
}

static double build_sqlite(const char *database_path, const WordRows *rows) {
    double started = monotonic_seconds();
    sqlite3 *database = NULL;
    int open_result = sqlite3_open(database_path, &database);
    check_sqlite(open_result, database, "create SQLite benchmark database");
    execute_sql(database, "CREATE TABLE words (word TEXT PRIMARY KEY, frequency INTEGER, "
                          "translation TEXT, ipa TEXT)");
    execute_sql(database, "BEGIN");

    sqlite3_stmt *statement = NULL;
    check_sqlite(sqlite3_prepare_v2(database,
                                    "INSERT INTO words (word, frequency, translation, ipa) VALUES "
                                    "(?, ?, ?, ?)",
                                    -1, &statement, NULL),
                 database, "prepare SQLite insert");
    for (size_t index = 0; index < rows->count; ++index) {
        const WordRow *row = &rows->items[index];
        check_sqlite(sqlite3_bind_text(statement, 1, row->word, -1, SQLITE_STATIC), database, "bind SQLite word");
        check_sqlite(sqlite3_bind_int64(statement, 2, (sqlite3_int64)row->frequency), database, "bind SQLite frequency");
        check_sqlite(sqlite3_bind_text(statement, 3, row->translation, -1, SQLITE_STATIC), database, "bind SQLite translation");
        check_sqlite(sqlite3_bind_text(statement, 4, row->ipa, -1, SQLITE_STATIC), database, "bind SQLite IPA");
        check_sqlite(sqlite3_step(statement), database, "insert SQLite word");
        check_sqlite(sqlite3_reset(statement), database, "reset SQLite insert");
        check_sqlite(sqlite3_clear_bindings(statement), database, "clear SQLite insert bindings");
    }
    check_sqlite(sqlite3_finalize(statement), database, "finalize SQLite insert");
    execute_sql(database, "COMMIT");
    execute_sql(database, "CREATE INDEX idx_word ON words(word)");
    check_sqlite(sqlite3_close(database), database, "close SQLite benchmark database");
    return monotonic_seconds() - started;
}

static void write_uint64_big_endian(unsigned char *destination, uint64_t value) {
    for (size_t index = 0; index < 8; ++index) {
        destination[7 - index] = (unsigned char)(value & 0xff);
        value >>= 8;
    }
}

static void write_uint32_big_endian(unsigned char *destination, uint32_t value) {
    for (size_t index = 0; index < 4; ++index) {
        destination[3 - index] = (unsigned char)(value & 0xff);
        value >>= 8;
    }
}

static uint64_t read_uint64_big_endian(const unsigned char *source) {
    uint64_t value = 0;
    for (size_t index = 0; index < 8; ++index) {
        value = (value << 8) | source[index];
    }
    return value;
}

static uint32_t read_uint32_big_endian(const unsigned char *source) {
    uint32_t value = 0;
    for (size_t index = 0; index < 4; ++index) {
        value = (value << 8) | source[index];
    }
    return value;
}

static MDB_val encode_lmdb_value(const WordRow *row) {
    size_t translation_size = strlen(row->translation);
    size_t ipa_size = strlen(row->ipa);
    if (translation_size > UINT32_MAX) {
        fail("translation is too large for LMDB encoding");
    }
    size_t total_size = 8 + 4 + translation_size + ipa_size;
    unsigned char *bytes = checked_malloc(total_size);
    write_uint64_big_endian(bytes, row->frequency);
    write_uint32_big_endian(bytes + 8, (uint32_t)translation_size);
    memcpy(bytes + 12, row->translation, translation_size);
    memcpy(bytes + 12 + translation_size, row->ipa, ipa_size);
    return (MDB_val){.mv_size = total_size, .mv_data = bytes};
}

static double build_lmdb(const char *database_path, const WordRows *rows) {
    double started = monotonic_seconds();
    if (mkdir(database_path, 0755) != 0) {
        fail_errno("create LMDB directory");
    }

    MDB_env *environment = NULL;
    check_lmdb(mdb_env_create(&environment), "create LMDB environment");
    check_lmdb(mdb_env_set_mapsize(environment, LMDB_MAP_SIZE), "set LMDB map size");
    check_lmdb(mdb_env_open(environment, database_path, 0, 0644), "open LMDB environment");

    MDB_txn *transaction = NULL;
    MDB_dbi database;
    check_lmdb(mdb_txn_begin(environment, NULL, 0, &transaction), "begin LMDB build transaction");
    check_lmdb(mdb_dbi_open(transaction, NULL, 0, &database), "open LMDB database");
    for (size_t index = 0; index < rows->count; ++index) {
        const WordRow *row = &rows->items[index];
        MDB_val key = {.mv_size = strlen(row->word), .mv_data = row->word};
        MDB_val value = encode_lmdb_value(row);
        int result = mdb_put(transaction, database, &key, &value, MDB_APPEND);
        free(value.mv_data);
        check_lmdb(result, "append LMDB word");
    }
    check_lmdb(mdb_txn_commit(transaction), "commit LMDB build transaction");
    check_lmdb(mdb_env_sync(environment, 1), "sync LMDB environment");
    mdb_dbi_close(environment, database);
    mdb_env_close(environment);
    return monotonic_seconds() - started;
}

static void append_prefix_result(PrefixResults *results, const void *word, size_t word_size, uint64_t frequency) {
    if (results->count == results->capacity) {
        results->capacity = results->capacity == 0 ? 64 : results->capacity * 2;
        results->items = checked_realloc(results->items, results->capacity * sizeof(*results->items));
    }
    PrefixResult *result = &results->items[results->count++];
    result->word = copy_bytes(word, word_size);
    result->frequency = frequency;
}

static int compare_prefix_results(const void *left_pointer, const void *right_pointer) {
    const PrefixResult *left = left_pointer;
    const PrefixResult *right = right_pointer;
    if (left->frequency > right->frequency) {
        return -1;
    }
    if (left->frequency < right->frequency) {
        return 1;
    }
    return strcmp(left->word, right->word);
}

static void sort_prefix_results(PrefixResults *results) {
    qsort(results->items, results->count, sizeof(*results->items), compare_prefix_results);
}

static void free_prefix_results(PrefixResults *results) {
    for (size_t index = 0; index < results->count; ++index) {
        free(results->items[index].word);
    }
    free(results->items);
    *results = (PrefixResults){0};
}

static char *prefix_upper_bound(const char *prefix) {
    size_t length = strlen(prefix);
    if (length == 0) {
        fail("prefix cannot be empty");
    }
    char *upper_bound = copy_bytes(prefix, length);
    for (size_t index = length; index > 0; --index) {
        unsigned char byte = (unsigned char)upper_bound[index - 1];
        if (byte < 0x7f) {
            upper_bound[index - 1] = (char)(byte + 1);
            upper_bound[index] = '\0';
            return upper_bound;
        }
    }
    free(upper_bound);
    fail("prefix must contain an ASCII byte below 0x7f");
    return NULL;
}

static SQLiteQueries open_sqlite_queries(const char *database_path) {
    SQLiteQueries queries = {0};
    int open_result = sqlite3_open_v2(database_path, &queries.database, SQLITE_OPEN_READONLY, NULL);
    check_sqlite(open_result, queries.database, "open SQLite queries database");
    check_sqlite(sqlite3_prepare_v2(queries.database,
                                    "SELECT word FROM words WHERE word LIKE ? ORDER BY "
                                    "frequency DESC, word ASC",
                                    -1, &queries.like_statement, NULL),
                 queries.database, "prepare SQLite LIKE query");
    check_sqlite(sqlite3_prepare_v2(queries.database,
                                    "SELECT word FROM words WHERE word >= ? AND word < ? "
                                    "ORDER BY frequency DESC, word ASC",
                                    -1, &queries.range_statement, NULL),
                 queries.database, "prepare SQLite range query");
    check_sqlite(sqlite3_prepare_v2(queries.database, "SELECT frequency, translation, ipa FROM words WHERE word = ?", -1,
                                    &queries.exact_statement, NULL),
                 queries.database, "prepare SQLite exact query");
    return queries;
}

static void close_sqlite_queries(SQLiteQueries *queries) {
    check_sqlite(sqlite3_finalize(queries->like_statement), queries->database, "finalize SQLite LIKE query");
    check_sqlite(sqlite3_finalize(queries->range_statement), queries->database, "finalize SQLite range query");
    check_sqlite(sqlite3_finalize(queries->exact_statement), queries->database, "finalize SQLite exact query");
    check_sqlite(sqlite3_close(queries->database), queries->database, "close SQLite queries database");
    *queries = (SQLiteQueries){0};
}

static PrefixResults run_sqlite_prefix(sqlite3 *database, sqlite3_stmt *statement, const char *prefix, const char *upper_bound) {
    PrefixResults results = {0};
    char *pattern = NULL;
    if (upper_bound == NULL) {
        size_t length = strlen(prefix);
        pattern = checked_malloc(length + 2);
        memcpy(pattern, prefix, length);
        pattern[length] = '%';
        pattern[length + 1] = '\0';
        check_sqlite(sqlite3_bind_text(statement, 1, pattern, -1, SQLITE_TRANSIENT), database, "bind SQLite LIKE prefix");
    } else {
        check_sqlite(sqlite3_bind_text(statement, 1, prefix, -1, SQLITE_STATIC), database, "bind SQLite range start");
        check_sqlite(sqlite3_bind_text(statement, 2, upper_bound, -1, SQLITE_STATIC), database, "bind SQLite range end");
    }

    int result;
    while ((result = sqlite3_step(statement)) == SQLITE_ROW) {
        const unsigned char *word = sqlite3_column_text(statement, 0);
        int word_size = sqlite3_column_bytes(statement, 0);
        append_prefix_result(&results, word, (size_t)word_size, 0);
    }
    if (result != SQLITE_DONE) {
        check_sqlite(result, database, "execute SQLite prefix query");
    }
    check_sqlite(sqlite3_reset(statement), database, "reset SQLite prefix query");
    check_sqlite(sqlite3_clear_bindings(statement), database, "clear SQLite prefix bindings");
    free(pattern);
    return results;
}

static PrefixResults sqlite_prefix_like(SQLiteQueries *queries, const char *prefix) {
    return run_sqlite_prefix(queries->database, queries->like_statement, prefix, NULL);
}

static PrefixResults sqlite_prefix_range(SQLiteQueries *queries, const char *prefix) {
    char *upper_bound = prefix_upper_bound(prefix);
    PrefixResults results = run_sqlite_prefix(queries->database, queries->range_statement, prefix, upper_bound);
    free(upper_bound);
    return results;
}

static LMDBQueries open_lmdb_queries(const char *database_path) {
    LMDBQueries queries = {0};
    check_lmdb(mdb_env_create(&queries.environment), "create LMDB read environment");
    check_lmdb(mdb_env_open(queries.environment, database_path, MDB_RDONLY | MDB_NOTLS | MDB_NOLOCK, 0444), "open LMDB read environment");
    MDB_txn *transaction = NULL;
    check_lmdb(mdb_txn_begin(queries.environment, NULL, MDB_RDONLY, &transaction), "begin LMDB setup transaction");
    check_lmdb(mdb_dbi_open(transaction, NULL, 0, &queries.database), "open LMDB read database");
    mdb_txn_abort(transaction);
    return queries;
}

static void close_lmdb_queries(LMDBQueries *queries) {
    mdb_dbi_close(queries->environment, queries->database);
    mdb_env_close(queries->environment);
    *queries = (LMDBQueries){0};
}

static PrefixResults lmdb_prefix(LMDBQueries *queries, const char *prefix) {
    PrefixResults results = {0};
    size_t prefix_size = strlen(prefix);
    MDB_txn *transaction = NULL;
    MDB_cursor *cursor = NULL;
    check_lmdb(mdb_txn_begin(queries->environment, NULL, MDB_RDONLY, &transaction), "begin LMDB prefix transaction");
    check_lmdb(mdb_cursor_open(transaction, queries->database, &cursor), "open LMDB prefix cursor");

    MDB_val key = {.mv_size = prefix_size, .mv_data = (void *)prefix};
    MDB_val value;
    int result = mdb_cursor_get(cursor, &key, &value, MDB_SET_RANGE);
    while (result == MDB_SUCCESS) {
        if (key.mv_size < prefix_size || memcmp(key.mv_data, prefix, prefix_size) != 0) {
            break;
        }
        if (value.mv_size < 12) {
            fail("invalid LMDB value encountered during prefix query");
        }
        append_prefix_result(&results, key.mv_data, key.mv_size, read_uint64_big_endian(value.mv_data));
        result = mdb_cursor_get(cursor, &key, &value, MDB_NEXT);
    }
    if (result != MDB_SUCCESS && result != MDB_NOTFOUND) {
        check_lmdb(result, "iterate LMDB prefix cursor");
    }
    mdb_cursor_close(cursor);
    mdb_txn_abort(transaction);
    sort_prefix_results(&results);
    return results;
}

static ExactResult sqlite_exact(SQLiteQueries *queries, const char *word) {
    ExactResult result = {0};
    check_sqlite(sqlite3_bind_text(queries->exact_statement, 1, word, -1, SQLITE_STATIC), queries->database, "bind SQLite exact word");
    int step_result = sqlite3_step(queries->exact_statement);
    if (step_result == SQLITE_ROW) {
        result.found = true;
        result.frequency = (uint64_t)sqlite3_column_int64(queries->exact_statement, 0);
        result.translation = copy_sqlite_text(queries->exact_statement, 1);
        result.ipa = copy_sqlite_text(queries->exact_statement, 2);
        step_result = sqlite3_step(queries->exact_statement);
    }
    if (step_result != SQLITE_DONE) {
        check_sqlite(step_result, queries->database, "execute SQLite exact query");
    }
    check_sqlite(sqlite3_reset(queries->exact_statement), queries->database, "reset SQLite exact query");
    check_sqlite(sqlite3_clear_bindings(queries->exact_statement), queries->database, "clear SQLite exact bindings");
    return result;
}

static ExactResult lmdb_exact(LMDBQueries *queries, const char *word) {
    ExactResult result = {0};
    MDB_txn *transaction = NULL;
    check_lmdb(mdb_txn_begin(queries->environment, NULL, MDB_RDONLY, &transaction), "begin LMDB exact transaction");
    MDB_val key = {.mv_size = strlen(word), .mv_data = (void *)word};
    MDB_val value;
    int lookup_result = mdb_get(transaction, queries->database, &key, &value);
    if (lookup_result == MDB_SUCCESS) {
        if (value.mv_size < 12) {
            fail("invalid LMDB exact value");
        }
        const unsigned char *bytes = value.mv_data;
        uint32_t translation_size = read_uint32_big_endian(bytes + 8);
        if ((size_t)translation_size > value.mv_size - 12) {
            fail("invalid LMDB translation length");
        }
        result.found = true;
        result.frequency = read_uint64_big_endian(bytes);
        result.translation = copy_bytes(bytes + 12, translation_size);
        result.ipa = copy_bytes(bytes + 12 + translation_size, value.mv_size - 12 - translation_size);
    } else if (lookup_result != MDB_NOTFOUND) {
        check_lmdb(lookup_result, "execute LMDB exact query");
    }
    mdb_txn_abort(transaction);
    return result;
}

static void free_exact_result(ExactResult *result) {
    free(result->translation);
    free(result->ipa);
    *result = (ExactResult){0};
}

static bool prefix_results_equal(const PrefixResults *left, const PrefixResults *right) {
    if (left->count != right->count) {
        return false;
    }
    for (size_t index = 0; index < left->count; ++index) {
        if (strcmp(left->items[index].word, right->items[index].word) != 0) {
            return false;
        }
    }
    return true;
}

static bool exact_results_equal(const ExactResult *left, const ExactResult *right) {
    if (left->found != right->found) {
        return false;
    }
    if (!left->found) {
        return true;
    }
    return left->frequency == right->frequency && strcmp(left->translation, right->translation) == 0 && strcmp(left->ipa, right->ipa) == 0;
}

static void validate_results(SQLiteQueries *sqlite_queries, LMDBQueries *lmdb_queries, const char **prefixes, size_t prefix_count) {
    for (size_t index = 0; index < prefix_count; ++index) {
        PrefixResults like = sqlite_prefix_like(sqlite_queries, prefixes[index]);
        PrefixResults range = sqlite_prefix_range(sqlite_queries, prefixes[index]);
        PrefixResults lmdb = lmdb_prefix(lmdb_queries, prefixes[index]);
        if (!prefix_results_equal(&like, &range) || !prefix_results_equal(&range, &lmdb)) {
            fprintf(stderr, "error: backend results differ for prefix %s\n", prefixes[index]);
            exit(EXIT_FAILURE);
        }
        free_prefix_results(&like);
        free_prefix_results(&range);
        free_prefix_results(&lmdb);
    }

    size_t exact_count = sizeof(DEFAULT_EXACT_WORDS) / sizeof(DEFAULT_EXACT_WORDS[0]);
    for (size_t index = 0; index < exact_count; ++index) {
        ExactResult sqlite_result = sqlite_exact(sqlite_queries, DEFAULT_EXACT_WORDS[index]);
        ExactResult lmdb_result = lmdb_exact(lmdb_queries, DEFAULT_EXACT_WORDS[index]);
        if (!exact_results_equal(&sqlite_result, &lmdb_result)) {
            fprintf(stderr, "error: backend exact results differ for word %s\n", DEFAULT_EXACT_WORDS[index]);
            exit(EXIT_FAILURE);
        }
        free_exact_result(&sqlite_result);
        free_exact_result(&lmdb_result);
    }
}

static void measure_sqlite_like(void *context, const char *input) {
    PrefixResults results = sqlite_prefix_like(context, input);
    benchmark_sink += results.count;
    free_prefix_results(&results);
}

static void measure_sqlite_range(void *context, const char *input) {
    PrefixResults results = sqlite_prefix_range(context, input);
    benchmark_sink += results.count;
    free_prefix_results(&results);
}

static void measure_lmdb_prefix(void *context, const char *input) {
    PrefixResults results = lmdb_prefix(context, input);
    benchmark_sink += results.count;
    free_prefix_results(&results);
}

static void measure_sqlite_exact(void *context, const char *input) {
    ExactResult result = sqlite_exact(context, input);
    benchmark_sink += result.found ? result.frequency : 1;
    free_exact_result(&result);
}

static void measure_lmdb_exact(void *context, const char *input) {
    ExactResult result = lmdb_exact(context, input);
    benchmark_sink += result.found ? result.frequency : 1;
    free_exact_result(&result);
}

static Samples measure(MeasuredOperation operation, void *context, const char **inputs, size_t input_count, size_t iterations,
                       size_t warmup) {
    for (size_t iteration = 0; iteration < warmup; ++iteration) {
        for (size_t input = 0; input < input_count; ++input) {
            operation(context, inputs[input]);
        }
    }

    Samples samples = {
        .values = checked_malloc(input_count * iterations * sizeof(double)),
        .input_count = input_count,
        .iterations = iterations,
    };
    for (size_t iteration = 0; iteration < iterations; ++iteration) {
        for (size_t input = 0; input < input_count; ++input) {
            double started = monotonic_seconds();
            operation(context, inputs[input]);
            samples.values[input * iterations + iteration] = (monotonic_seconds() - started) * 1000.0;
        }
    }
    return samples;
}

static int compare_doubles(const void *left, const void *right) {
    double left_value = *(const double *)left;
    double right_value = *(const double *)right;
    return (left_value > right_value) - (left_value < right_value);
}

static double percentile(const double *values, size_t count, double percentage) {
    if (count == 0) {
        fail("cannot calculate percentile of empty samples");
    }
    double *ordered = checked_malloc(count * sizeof(*ordered));
    memcpy(ordered, values, count * sizeof(*ordered));
    qsort(ordered, count, sizeof(*ordered), compare_doubles);
    size_t index = (size_t)ceil((double)count * percentage);
    index = index == 0 ? 0 : index - 1;
    double result = ordered[index];
    free(ordered);
    return result;
}

static double median(const double *values, size_t count) {
    double *ordered = checked_malloc(count * sizeof(*ordered));
    memcpy(ordered, values, count * sizeof(*ordered));
    qsort(ordered, count, sizeof(*ordered), compare_doubles);
    double result = count % 2 == 0 ? (ordered[count / 2 - 1] + ordered[count / 2]) / 2.0 : ordered[count / 2];
    free(ordered);
    return result;
}

static void combined_stats(const Samples *samples, double *median_result, double *p95_result) {
    size_t count = samples->input_count * samples->iterations;
    *median_result = median(samples->values, count);
    *p95_result = percentile(samples->values, count, 0.95);
}

static void free_samples(Samples *samples) {
    free(samples->values);
    *samples = (Samples){0};
}

static FileSize file_size(const char *path) {
    struct stat status;
    if (stat(path, &status) != 0) {
        fail_errno("stat benchmark file");
    }
    if (!S_ISDIR(status.st_mode)) {
        return (FileSize){.logical = (uint64_t)status.st_size, .allocated = (uint64_t)status.st_blocks * 512};
    }

    DIR *directory = opendir(path);
    if (directory == NULL) {
        fail_errno("open benchmark directory");
    }
    FileSize size = {0};
    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        char item_path[PATH_MAX];
        if (snprintf(item_path, sizeof(item_path), "%s/%s", path, entry->d_name) >= (int)sizeof(item_path)) {
            fail("benchmark file path is too long");
        }
        if (stat(item_path, &status) != 0) {
            fail_errno("stat benchmark directory entry");
        }
        if (S_ISREG(status.st_mode)) {
            size.logical += (uint64_t)status.st_size;
            size.allocated += (uint64_t)status.st_blocks * 512;
        }
    }
    closedir(directory);
    return size;
}

static double mebibytes(uint64_t bytes) { return (double)bytes / (1024.0 * 1024.0); }

static void print_measurement(const char *name, const Samples *samples) {
    double p50;
    double p95;
    combined_stats(samples, &p50, &p95);
    printf("| %s | %.4f | %.4f |\n", name, p50, p95);
}

static void print_query_plan(sqlite3 *database, const char *label, const char *sql, const char *first, const char *second) {
    char query[1024];
    if (snprintf(query, sizeof(query), "EXPLAIN QUERY PLAN %s", sql) >= (int)sizeof(query)) {
        fail("query plan SQL is too long");
    }
    sqlite3_stmt *statement = NULL;
    check_sqlite(sqlite3_prepare_v2(database, query, -1, &statement, NULL), database, "prepare SQLite query plan");
    check_sqlite(sqlite3_bind_text(statement, 1, first, -1, SQLITE_STATIC), database, "bind first query plan parameter");
    if (second != NULL) {
        check_sqlite(sqlite3_bind_text(statement, 2, second, -1, SQLITE_STATIC), database, "bind second query plan parameter");
    }
    printf("- %s: `", label);
    bool first_row = true;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        if (!first_row) {
            printf("; ");
        }
        printf("%s", sqlite3_column_text(statement, 3));
        first_row = false;
    }
    printf("`\n");
    check_sqlite(sqlite3_finalize(statement), database, "finalize SQLite query plan");
}

static void remove_benchmark_files(const char *temporary_directory, const char *sqlite_path, const char *lmdb_path) {
    if (unlink(sqlite_path) != 0 && errno != ENOENT) {
        fail_errno("remove temporary SQLite database");
    }
    char path[PATH_MAX];
    const char *lmdb_files[] = {"data.mdb", "lock.mdb"};
    for (size_t index = 0; index < 2; ++index) {
        if (snprintf(path, sizeof(path), "%s/%s", lmdb_path, lmdb_files[index]) >= (int)sizeof(path)) {
            fail("temporary LMDB path is too long");
        }
        if (unlink(path) != 0 && errno != ENOENT) {
            fail_errno("remove temporary LMDB file");
        }
    }
    if (rmdir(lmdb_path) != 0) {
        fail_errno("remove temporary LMDB directory");
    }
    if (rmdir(temporary_directory) != 0) {
        fail_errno("remove benchmark temporary directory");
    }
}

static size_t parse_size(const char *value, const char *option) {
    char *end = NULL;
    errno = 0;
    unsigned long parsed = strtoul(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0' || parsed > SIZE_MAX) {
        fprintf(stderr, "error: invalid value for %s: %s\n", option, value);
        exit(EXIT_FAILURE);
    }
    return (size_t)parsed;
}

static void print_usage(const char *program) { printf("Usage: %s [--database PATH] [--iterations N] [--warmup N]\n", program); }

int main(int argc, char **argv) {
    const char *source_database = DEFAULT_DATABASE;
    size_t iterations = 100;
    size_t warmup = 10;
    for (int index = 1; index < argc; ++index) {
        if (strcmp(argv[index], "--database") == 0 && index + 1 < argc) {
            source_database = argv[++index];
        } else if (strcmp(argv[index], "--iterations") == 0 && index + 1 < argc) {
            iterations = parse_size(argv[++index], "--iterations");
        } else if (strcmp(argv[index], "--warmup") == 0 && index + 1 < argc) {
            warmup = parse_size(argv[++index], "--warmup");
        } else if (strcmp(argv[index], "--help") == 0) {
            print_usage(argv[0]);
            return EXIT_SUCCESS;
        } else {
            print_usage(argv[0]);
            return EXIT_FAILURE;
        }
    }
    if (iterations == 0) {
        fail("iterations must be positive");
    }

    size_t ngram_count;
    WordRows rows = load_rows(source_database, &ngram_count);
    if (rows.count == 0) {
        fail("source dictionary contains no words");
    }

    char temporary_directory[] = "/tmp/hallelujah-native-storage-XXXXXX";
    if (mkdtemp(temporary_directory) == NULL) {
        fail_errno("create benchmark temporary directory");
    }
    char sqlite_path[PATH_MAX];
    char lmdb_path[PATH_MAX];
    if (snprintf(sqlite_path, sizeof(sqlite_path), "%s/words.sqlite3", temporary_directory) >= (int)sizeof(sqlite_path) ||
        snprintf(lmdb_path, sizeof(lmdb_path), "%s/words.lmdb", temporary_directory) >= (int)sizeof(lmdb_path)) {
        fail("benchmark temporary path is too long");
    }

    double sqlite_build_time = build_sqlite(sqlite_path, &rows);
    double lmdb_build_time = build_lmdb(lmdb_path, &rows);
    SQLiteQueries sqlite_queries = open_sqlite_queries(sqlite_path);
    LMDBQueries lmdb_queries = open_lmdb_queries(lmdb_path);

    MDB_txn *count_transaction = NULL;
    MDB_stat lmdb_statistics;
    check_lmdb(mdb_txn_begin(lmdb_queries.environment, NULL, MDB_RDONLY, &count_transaction), "begin LMDB count transaction");
    check_lmdb(mdb_stat(count_transaction, lmdb_queries.database, &lmdb_statistics), "read LMDB statistics");
    mdb_txn_abort(count_transaction);
    if (lmdb_statistics.ms_entries != rows.count) {
        fail("LMDB row count differs from the SQLite source");
    }

    size_t prefix_count = sizeof(DEFAULT_PREFIXES) / sizeof(DEFAULT_PREFIXES[0]);
    size_t exact_count = sizeof(DEFAULT_EXACT_WORDS) / sizeof(DEFAULT_EXACT_WORDS[0]);
    validate_results(&sqlite_queries, &lmdb_queries, DEFAULT_PREFIXES, prefix_count);

    Samples like_samples = measure(measure_sqlite_like, &sqlite_queries, DEFAULT_PREFIXES, prefix_count, iterations, warmup);
    Samples range_samples = measure(measure_sqlite_range, &sqlite_queries, DEFAULT_PREFIXES, prefix_count, iterations, warmup);
    Samples lmdb_prefix_samples = measure(measure_lmdb_prefix, &lmdb_queries, DEFAULT_PREFIXES, prefix_count, iterations, warmup);
    Samples sqlite_exact_samples = measure(measure_sqlite_exact, &sqlite_queries, DEFAULT_EXACT_WORDS, exact_count, iterations, warmup);
    Samples lmdb_exact_samples = measure(measure_lmdb_exact, &lmdb_queries, DEFAULT_EXACT_WORDS, exact_count, iterations, warmup);

    FileSize source_size = file_size(source_database);
    FileSize sqlite_size = file_size(sqlite_path);
    FileSize lmdb_size = file_size(lmdb_path);

    struct utsname system_information;
    if (uname(&system_information) != 0) {
        fail_errno("read system information");
    }
    char cpu_name[256] = "unknown";
    size_t cpu_name_size = sizeof(cpu_name);
    if (sysctlbyname("machdep.cpu.brand_string", cpu_name, &cpu_name_size, NULL, 0) != 0) {
        snprintf(cpu_name, sizeof(cpu_name), "%s", system_information.machine);
    }
    int lmdb_major;
    int lmdb_minor;
    int lmdb_patch;
    mdb_version(&lmdb_major, &lmdb_minor, &lmdb_patch);

    printf("# Hallelujah native SQLite vs LMDB benchmark\n\n");
    printf("- Platform: %s %s (%s)\n", system_information.sysname, system_information.release, system_information.machine);
    printf("- CPU: %s\n", cpu_name);
    printf("- SQLite: %s\n", sqlite3_libversion());
    printf("- LMDB: %d.%d.%d\n", lmdb_major, lmdb_minor, lmdb_patch);
    printf("- Words: %zu\n", rows.count);
    printf("- N-grams present in source SQLite file: %zu\n", ngram_count);
    printf("- Iterations per input: %zu\n", iterations);
    printf("- Cache state: warm OS page cache; persistent SQLite statements and "
           "LMDB environment\n\n");

    printf("## Build and on-disk size\n\n");
    printf("| Backend | Build (s) | Logical (MiB) | Allocated (MiB) |\n");
    printf("| --- | ---: | ---: | ---: |\n");
    printf("| Bundled SQLite source | n/a | %.2f | %.2f |\n", mebibytes(source_size.logical), mebibytes(source_size.allocated));
    printf("| SQLite (words only, current schema) | %.3f | %.2f | %.2f |\n", sqlite_build_time, mebibytes(sqlite_size.logical),
           mebibytes(sqlite_size.allocated));
    printf("| LMDB (words only) | %.3f | %.2f | %.2f |\n\n", lmdb_build_time, mebibytes(lmdb_size.logical), mebibytes(lmdb_size.allocated));

    printf("## Warm query latency\n\n");
    printf("| Operation | p50 (ms) | p95 (ms) |\n");
    printf("| --- | ---: | ---: |\n");
    print_measurement("SQLite prefix (`LIKE`, current)", &like_samples);
    print_measurement("SQLite prefix (indexed range)", &range_samples);
    print_measurement("LMDB prefix cursor", &lmdb_prefix_samples);
    print_measurement("SQLite exact lookup", &sqlite_exact_samples);
    print_measurement("LMDB exact lookup", &lmdb_exact_samples);

    printf("\n## Prefix detail (median latency)\n\n");
    printf("| Prefix | Matches | SQLite `LIKE` (ms) | SQLite range (ms) | LMDB "
           "(ms) |\n");
    printf("| --- | ---: | ---: | ---: | ---: |\n");
    for (size_t index = 0; index < prefix_count; ++index) {
        PrefixResults results = sqlite_prefix_range(&sqlite_queries, DEFAULT_PREFIXES[index]);
        printf("| `%s` | %zu | %.4f | %.4f | %.4f |\n", DEFAULT_PREFIXES[index], results.count,
               median(&like_samples.values[index * iterations], iterations), median(&range_samples.values[index * iterations], iterations),
               median(&lmdb_prefix_samples.values[index * iterations], iterations));
        free_prefix_results(&results);
    }

    printf("\n## SQLite query plans\n\n");
    print_query_plan(sqlite_queries.database, "Current `LIKE`",
                     "SELECT word FROM words WHERE word LIKE ? ORDER BY frequency "
                     "DESC",
                     "tes%", NULL);
    print_query_plan(sqlite_queries.database, "Indexed range",
                     "SELECT word FROM words WHERE word >= ? AND word < ? ORDER BY "
                     "frequency DESC",
                     "tes", "tet");

    free_samples(&like_samples);
    free_samples(&range_samples);
    free_samples(&lmdb_prefix_samples);
    free_samples(&sqlite_exact_samples);
    free_samples(&lmdb_exact_samples);
    close_sqlite_queries(&sqlite_queries);
    close_lmdb_queries(&lmdb_queries);
    free_rows(&rows);
    remove_benchmark_files(temporary_directory, sqlite_path, lmdb_path);
    return benchmark_sink == UINT64_MAX ? EXIT_FAILURE : EXIT_SUCCESS;
}
