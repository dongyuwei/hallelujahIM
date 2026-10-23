#import "PinyinCandidateRows.h"

static const NSInteger kMinPosition = 1;
static const NSInteger kMaxPosition = 5;

typedef NS_ENUM(NSInteger, RowKind) {
    RowKindRime,
    RowKindRawInput,
    RowKindEnglish,
};

@interface PinyinCandidateRows ()

@property(nonatomic, copy) NSArray<NSString *> *rows;
@property(nonatomic) NSInteger rawInputRow;
@property(nonatomic, copy) NSArray<NSNumber *> *rowKinds;
@property(nonatomic, copy) NSArray<NSNumber *> *rimeIndexes;

@end

@implementation PinyinCandidateRows

+ (NSInteger)maxPosition {
    return kMaxPosition;
}

+ (NSInteger)minPosition {
    return kMinPosition;
}

+ (NSInteger)clampedPosition:(NSInteger)position {
    return MAX(kMinPosition, MIN(kMaxPosition, position));
}

- (instancetype)initWithRawInput:(NSString *)rawInput
               englishCandidates:(NSArray<NSString *> *)englishCandidates
                  rimeCandidates:(NSArray<NSString *> *)rimeCandidates
               preferredPosition:(NSInteger)preferredPosition {
    self = [super init];
    if (self) {
        _rawInputRow = NSNotFound;
        NSMutableArray<NSString *> *rows = [NSMutableArray array];
        NSMutableArray<NSNumber *> *kinds = [NSMutableArray array];
        NSMutableArray<NSNumber *> *rimeIndexes = [NSMutableArray array];

        NSArray<NSString *> *english = englishCandidates ?: @[];
        NSArray<NSString *> *rime = rimeCandidates ?: @[];

        // When the English candidates already include the typed word exactly,
        // that row commits the same text as the raw-input row, so the extra
        // raw-input row is dropped. Filtering the word instead would promote a
        // longer completion to row 0, and space would commit a word the user
        // never typed. Otherwise the raw input keeps its configured digit: its
        // row index is measured over the assembled row list, English rows
        // included, and a short page can only offer its last row.
        BOOL rawInputListed = NO;
        for (NSString *word in english) {
            if ([word compare:rawInput options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                rawInputListed = YES;
                break;
            }
        }
        BOOL hasRawInput = rawInput.length > 0 && !rawInputListed;
        if (hasRawInput) {
            _rawInputRow = MIN([PinyinCandidateRows clampedPosition:preferredPosition] - 1, (NSInteger)(english.count + rime.count));
        }

        NSUInteger englishIndex = 0;
        NSUInteger rimeIndex = 0;
        NSUInteger total = english.count + rime.count + (hasRawInput ? 1 : 0);
        for (NSUInteger row = 0; row < total; row++) {
            if (hasRawInput && (NSInteger)row == _rawInputRow) {
                [rows addObject:rawInput];
                [kinds addObject:@(RowKindRawInput)];
                [rimeIndexes addObject:@(NSNotFound)];
            } else if (englishIndex < english.count) {
                [rows addObject:english[englishIndex++]];
                [kinds addObject:@(RowKindEnglish)];
                [rimeIndexes addObject:@(NSNotFound)];
            } else {
                [rows addObject:rime[rimeIndex]];
                [kinds addObject:@(RowKindRime)];
                [rimeIndexes addObject:@(rimeIndex++)];
            }
        }
        _rows = rows;
        _rowKinds = kinds;
        _rimeIndexes = rimeIndexes;
    }
    return self;
}

- (BOOL)rowIsRawInput:(NSInteger)row {
    return row == self.rawInputRow;
}

- (BOOL)rowIsEnglish:(NSInteger)row {
    return row >= 0 && row < (NSInteger)self.rowKinds.count && self.rowKinds[row].integerValue == RowKindEnglish;
}

- (NSInteger)rimeIndexForRow:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.rimeIndexes.count) {
        return NSNotFound;
    }
    return self.rimeIndexes[row].integerValue;
}

@end
