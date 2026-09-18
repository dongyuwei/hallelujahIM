#import "PinyinCandidateRows.h"

static const NSInteger kMinPosition = 1;
static const NSInteger kMaxPosition = 5;

@interface PinyinCandidateRows ()

@property(nonatomic, copy) NSArray<NSString *> *rows;
@property(nonatomic) NSInteger rawInputRow;

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
                  rimeCandidates:(NSArray<NSString *> *)rimeCandidates
               preferredPosition:(NSInteger)preferredPosition {
    self = [super init];
    if (self) {
        _rawInputRow = NSNotFound;
        NSMutableArray *rows = [NSMutableArray arrayWithArray:rimeCandidates ?: @[]];
        if (rawInput.length > 0) {
            // Splice the raw input into the page at the configured position;
            // a short page can only offer its last row.
            _rawInputRow = MIN([PinyinCandidateRows clampedPosition:preferredPosition] - 1, (NSInteger)rows.count);
            [rows insertObject:rawInput atIndex:_rawInputRow];
        }
        _rows = rows;
    }
    return self;
}

- (BOOL)rowIsRawInput:(NSInteger)row {
    return row == self.rawInputRow;
}

// The raw-input row pushes every Rime candidate below it down by one, so a
// panel row maps to the Rime page index below the splice and to itself above.
- (NSInteger)rimeIndexForRow:(NSInteger)row {
    if (row < self.rawInputRow) {
        return row;
    }
    return row - 1;
}

@end
