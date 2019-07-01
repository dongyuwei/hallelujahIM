#import "InputApplicationDelegate.h"

@implementation InputApplicationDelegate

- (NSMenu *)menu {
    return _menu;
}

- (void)awakeFromNib {
    NSMenuItem *preferenceMenuItem = [_menu itemWithTitle:@"Preferences"];
    NSMenuItem *aboutMenuItem = [_menu itemWithTitle:@"About"];

    if (preferenceMenuItem) {
        [preferenceMenuItem setAction:@selector(showIMEPreferences:)];
    }

    if (aboutMenuItem) {
        [aboutMenuItem setAction:@selector(clickAbout:)];
    }
}

@end
