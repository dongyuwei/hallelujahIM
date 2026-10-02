#import "CandidateTheme.h"

typedef struct {
    NSString *skinID;
    NSUInteger bg, border, word, wordActive, number, numberActive, pill;
    CGFloat radius;
} SkinSpec;

// verdant/carbon/graphite/matrix/tangerine clone the Sogou reference skins in
// ../Sogou-Input-Skin/Images; classic is the panel's pre-skin SwiftType palette.
static const SkinSpec kSkinSpecs[] = {
    {@"classic", 0x1B1B1B, 0x1B1B1B, 0xFCFCFC, 0xFFFFFF, 0xA0796A, 0xFFCC80, 0x533566, 6},
    {@"verdant", 0xFFFFFF, 0xECECEC, 0x3A3F45, 0x00A26B, 0xB4BAC0, 0x00A26B, 0xE8F6F0, 8},
    {@"carbon", 0x2B2E34, 0x2B2E34, 0xD9DCE1, 0xFFFFFF, 0x9BA0A8, 0xFFFFFF, 0x41454D, 4},
    {@"graphite", 0xFFFFFF, 0xE3E6EB, 0x2F3542, 0x151A23, 0x8A92A0, 0x151A23, 0xEAEDF2, 4},
    {@"matrix", 0x1B2530, 0x1B2530, 0xE9EEF3, 0x2BE4C0, 0x7E8D9B, 0x2BE4C0, 0x26343F, 4},
    {@"tangerine", 0xFFFFFF, 0xFF7A1E, 0x4A4F55, 0xF2740B, 0xB3B8BE, 0xF2740B, 0xFFF0E2, 4},
};

static const SkinSpec *FindSkin(NSString *skinID) {
    const size_t count = sizeof(kSkinSpecs) / sizeof(kSkinSpecs[0]);
    for (size_t i = 0; i < count; i++) {
        if ([kSkinSpecs[i].skinID isEqualToString:skinID]) {
            return &kSkinSpecs[i];
        }
    }
    return NULL;
}

static NSString *DefaultSkinID(void) { return @"matrix"; }

@implementation CandidateTheme

- (instancetype)initWithSpec:(const SkinSpec *)spec {
    self = [super init];
    if (self) {
        _skinID = [spec->skinID copy];
        _backgroundColor = spec->bg;
        _borderColor = spec->border;
        _cornerRadius = spec->radius;
        _wordColor = spec->word;
        _wordActiveColor = spec->wordActive;
        _numberColor = spec->number;
        _numberActiveColor = spec->numberActive;
        _pillColor = spec->pill;
    }
    return self;
}

+ (NSArray<NSString *> *)allSkinIDs {
    NSMutableArray *ids = [NSMutableArray array];
    const size_t count = sizeof(kSkinSpecs) / sizeof(kSkinSpecs[0]);
    for (size_t i = 0; i < count; i++) {
        [ids addObject:kSkinSpecs[i].skinID];
    }
    return ids;
}

+ (NSString *)defaultSkinID {
    return DefaultSkinID();
}

+ (instancetype)themeForSkinID:(NSString *)skinID {
    const SkinSpec *spec = skinID != nil ? FindSkin(skinID) : NULL;
    if (spec == NULL) {
        spec = FindSkin(DefaultSkinID());
    }
    return [[self alloc] initWithSpec:spec];
}

@end
