
#import <Cocoa/Cocoa.h>

@interface InputApplicationDelegate : NSObject {
    IBOutlet NSMenu *_menu;
    IBOutlet NSMenuItem *_aboutMenuItem;
}
- (NSMenu *)menu;

@end
