#import "PinyinCandidateRows.h"

@implementation PinyinCandidateRows

+ (NSArray<NSString *> *)rowsForRawInput:(NSString *)rawInput rimeCandidates:(NSArray<NSString *> *)rimeCandidates {
    if (rawInput.length == 0) {
        return [rimeCandidates copy] ?: @[];
    }
    return [@[ rawInput ] arrayByAddingObjectsFromArray:rimeCandidates ?: @[]];
}

+ (BOOL)rowIsRawInput:(NSInteger)row {
    return row == 0;
}

+ (NSInteger)rimeIndexForRow:(NSInteger)row {
    return row - 1;
}

@end
