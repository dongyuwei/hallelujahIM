#import "InputApplicationDelegate.h"
#import "InputController.h"

@implementation InputApplicationDelegate

- (NSMenu *)menu {
    return _menu;
}

+ (NSString *)buildVersion {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *build = [bundle objectForInfoDictionaryKey:@"HallelujahBuildVersion"];
    if (build.length > 0) {
        return build;
    }

    // Bundles predating the build stamp (and builds without a git checkout)
    // only carry the marketing version; show that rather than nothing.
    NSString *shortVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return shortVersion.length > 0 ? shortVersion : @"unknown";
}

+ (NSString *)buildDate {
    // Stored as an absolute Unix timestamp so the menu can render it in
    // whatever time zone the user happens to be in.
    NSString *epoch = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"HallelujahBuildEpoch"];
    NSTimeInterval seconds = epoch.doubleValue;
    if (epoch.length == 0 || seconds <= 0) {
        return nil;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    formatter.timeZone = [NSTimeZone localTimeZone];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:seconds]];
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

    // A disabled, last entry so "which build am I running?" is answered by the
    // menu itself. The text matches the `build-<sha>` release tag, which can be
    // pasted straight into a release URL.
    NSMenuItem *versionMenuItem =
        [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Version: %@", [InputApplicationDelegate buildVersion]]
                                   action:nil
                            keyEquivalent:@""];
    versionMenuItem.enabled = NO;
    [_menu addItem:versionMenuItem];

    NSString *buildDate = [InputApplicationDelegate buildDate];
    if (buildDate) {
        NSMenuItem *dateMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Built: %@", buildDate]
                                                              action:nil
                                                       keyEquivalent:@""];
        dateMenuItem.enabled = NO;
        [_menu addItem:dateMenuItem];
    }
}

@end
