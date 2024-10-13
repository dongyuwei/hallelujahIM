#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface ImeService : NSObject

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) FMDatabaseQueue *pyDbQueue;

- (instancetype)init;
- (NSArray<NSString *> *)fetchEnglishWordsWithPrefix:(NSString *)prefix;
- (NSArray<NSString *> *)fetchHanZiByPinyinWithPrefix:(NSString *)prefix;

@end
