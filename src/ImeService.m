#import "ImeService.h"
#import "FMDB.h"
#import "Pinyin.h"
#import "Word.h"

@implementation ImeService

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"english" withExtension:@"sqlite3"];
        if (!url) {
            NSLog(@"english.sqlite3 file not found");
            return nil;
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:url.path];
        if (!_dbQueue) {
            NSLog(@"Database connection to english.sqlite3 error");
        }
        
        NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"pinyin_data" withExtension:@"sqlite3"];
        if (!url2) {
            NSLog(@"pinyin_data.sqlite3 file not found");
            return nil;
        }
        _pyDbQueue = [FMDatabaseQueue databaseQueueWithPath:url2.path];
        if (!_pyDbQueue) {
            NSLog(@"Database connection to pinyin_data.sqlite3 error");
        }
    }
    return self;
}

- (NSArray<NSString *> *)fetchEnglishWordsWithPrefix:(NSString *)prefix {
    NSMutableArray<Word *> *words = [NSMutableArray array];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM words WHERE word LIKE ? ORDER BY freq DESC LIMIT 20";
        NSString *pattern = [NSString stringWithFormat:@"%@%%", prefix];
        FMResultSet *resultSet = [db executeQuery:sql, pattern];
        
        while ([resultSet next]) {
            Word *word = [[Word alloc] init];
            word.word = [resultSet stringForColumn:@"word"];
            word.freq = [resultSet intForColumn:@"freq"];
            [words addObject:word];
        }
    }];
    
    return [words valueForKey:@"word"];
}

- (NSArray<NSString *> *)fetchHanZiByPinyinWithPrefix:(NSString *)prefix {
    NSMutableArray<Pinyin *> *words = [NSMutableArray array];
    
    [self.pyDbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM pinyin_data WHERE py LIKE ? OR abbr LIKE ? ORDER BY freq DESC LIMIT 20";
        NSString *pattern = [NSString stringWithFormat:@"%@%%", prefix];
        FMResultSet *resultSet = [db executeQuery:sql, pattern, pattern];
        
        while ([resultSet next]) {
            Pinyin *pinyin = [[Pinyin alloc] init];
            pinyin.py = [resultSet stringForColumn:@"py"];
            pinyin.hz = [resultSet stringForColumn:@"hz"];
            pinyin.abbr = [resultSet stringForColumn:@"abbr"];
            pinyin.freq = [resultSet intForColumn:@"freq"];
            [words addObject:pinyin];
        }
    }];
    
    return [words valueForKey:@"hz"];
}

@end
