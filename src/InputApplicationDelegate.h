
#import <Cocoa/Cocoa.h>

@interface InputApplicationDelegate : NSObject {
    IBOutlet NSMenu *_menu;
    IBOutlet NSMenuItem *_aboutMenuItem;
}
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMenu *menu;

@end
