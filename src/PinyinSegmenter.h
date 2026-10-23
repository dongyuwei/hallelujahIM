#import <Foundation/Foundation.h>

// Full-pinyin segmentation: answers whether typed letters can still be
// complete pinyin. Rime cannot tell (it accepts abbreviations and fuzzy
// spellings), so this checks against the closed syllable inventory. Pure
// logic, no AppKit and no Rime session.
@interface PinyinSegmenter : NSObject

// YES when `input` splits entirely into complete pinyin syllables (zhongwen,
// women, name). NO for anything else: incomplete tails (sh, zhongw),
// non-pinyin letters (hello, str), uppercase, non-letters, or empty input.
+ (BOOL)canFullySegment:(NSString *)input;

@end
