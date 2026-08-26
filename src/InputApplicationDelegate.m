#import "InputApplicationDelegate.h"
#import "InputController.h"

@implementation InputApplicationDelegate

- (NSMenu *)menu {
    return _menu;
}

- (void)awakeFromNib {
    NSMenuItem *preferenceMenuItem = [_menu itemWithTitle:@"Preferences"];
    NSMenuItem *aboutMenuItem = [_menu itemWithTitle:@"About"];
    NSMenuItem *upgradeMenuItem = [_menu itemWithTitle:@"Upgrade"];

    if (preferenceMenuItem) {
        preferenceMenuItem.action = @selector(showIMEPreferences:);
    }

    if (upgradeMenuItem) {
        upgradeMenuItem.action = @selector(clickUpgrade:);
    }

    if (aboutMenuItem) {
        aboutMenuItem.action = @selector(clickAbout:);
    }
}

@end
