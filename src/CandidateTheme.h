#import <Foundation/Foundation.h>

// One candidate-panel skin: the colors and corner radius the panel draws with.
// Foundation-only (no AppKit) so the Tests target can link it; CandidatePanel
// converts the hex values to NSColor.
//
// All color slots are 0xRRGGBB.
@interface CandidateTheme : NSObject

@property(nonatomic, readonly, copy) NSString *skinID;
@property(nonatomic, readonly) NSUInteger backgroundColor;
@property(nonatomic, readonly) NSUInteger borderColor; // 1pt stroke around the panel
@property(nonatomic, readonly) CGFloat cornerRadius;
@property(nonatomic, readonly) NSUInteger wordColor; // unselected candidate text
@property(nonatomic, readonly) NSUInteger wordActiveColor;
@property(nonatomic, readonly) NSUInteger numberColor; // unselected selection key
@property(nonatomic, readonly) NSUInteger numberActiveColor;
@property(nonatomic, readonly) NSUInteger pillColor; // highlight behind the active cell

// The skin IDs the preference page offers, in display order.
+ (NSArray<NSString *> *)allSkinIDs;

+ (NSString *)defaultSkinID;

// Unknown (or nil) skin IDs fall back to the default skin.
+ (instancetype)themeForSkinID:(NSString *)skinID;

@end
