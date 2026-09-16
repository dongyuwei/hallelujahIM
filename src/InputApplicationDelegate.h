
#import <Cocoa/Cocoa.h>

@interface InputApplicationDelegate : NSObject {
    IBOutlet NSMenu *_menu;
    IBOutlet NSMenuItem *_aboutMenuItem;
}
@property(NS_NONATOMIC_IOSONLY, readonly, copy) NSMenu *menu;

// The `build-<short sha>` string stamped into the bundle by the "Inject build
// version" build phase; falls back to the marketing version when absent.
+ (NSString *)buildVersion;

// When the running binary was compiled, formatted in the local time zone, or
// nil for bundles that predate the build stamp.
+ (NSString *)buildDate;

@end
