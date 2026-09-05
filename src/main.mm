#import "CandidatePanel.h"
#import "ConversionEngine.h"
#import "RimeEngine.h"
#import "WebServer.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

NSUserDefaults *preference;
ConversionEngine *engine;
RimeEngine *rimeEngine;

CandidatePanel *sharedCandidates;

static const unsigned char kInstallLocation[] = "/Library/Input Methods/hallelujah.app";
static NSString *const kSourceID = @"github.dongyuwei.inputmethod.hallelujahInputMethod";

void registerInputSource() {
    CFURLRef installedLocationURL =
        CFURLCreateFromFileSystemRepresentation(NULL, kInstallLocation, strlen((const char *)kInstallLocation), NO);
    if (installedLocationURL) {
        TISRegisterInputSource(installedLocationURL);
        CFRelease(installedLocationURL);
        NSLog(@"Registered input source from %s", kInstallLocation);
    }
}

void activateInputSource() {
    CFArrayRef sourceList = TISCreateInputSourceList(NULL, true);
    for (int i = 0; i < CFArrayGetCount(sourceList); ++i) {
        TISInputSourceRef inputSource = (TISInputSourceRef)(CFArrayGetValueAtIndex(sourceList, i));
        NSString *sourceID = (__bridge NSString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
        if ([sourceID isEqualToString:kSourceID]) {
            // Always enable first; safe to call even if already enabled.
            TISEnableInputSource(inputSource);
            NSLog(@"Enabled input source: %@", sourceID);

            CFBooleanRef isSelectable = (CFBooleanRef)TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable);
            if (isSelectable && CFBooleanGetValue(isSelectable)) {
                TISSelectInputSource(inputSource);
                NSLog(@"Selected input source: %@", sourceID);
            }
        }
    }
    CFRelease(sourceList);
}

void deactivateInputSource() {
    CFArrayRef sourceList = TISCreateInputSourceList(NULL, true);
    for (int i = (int)CFArrayGetCount(sourceList); i > 0; --i) {
        TISInputSourceRef inputSource = (TISInputSourceRef)(CFArrayGetValueAtIndex(sourceList, i - 1));
        NSString *sourceID = (__bridge NSString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
        if ([sourceID isEqualToString:kSourceID]) {
            TISDeselectInputSource(inputSource);
            TISDisableInputSource(inputSource);
            NSLog(@"Deselected and disabled input source: %@", sourceID);
        }
    }
    CFRelease(sourceList);
}

void initPreference() {
    preference = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultPrefs =
        @{@"commitWordWithSpace" : @YES,
          @"showTranslation" : @YES,
          @"mixedInput" : @NO,
          @"useGridCandidatePanel" : @NO};
    [preference registerDefaults:defaultPrefs];
}

int main(int argc, char *argv[]) {
    if (argc > 1 && !strcmp("--deactivate", argv[1])) {
        deactivateInputSource();
        return 0;
    }

    if (argc > 1 && !strcmp("--install", argv[1])) {
        registerInputSource();
        // Give HIToolbox a moment to pick up the freshly-registered bundle
        // before we try to enable/select it.
        [NSThread sleepForTimeInterval:0.5];
        activateInputSource();
        return 0;
    }

    NSString *identifier = [NSBundle mainBundle].bundleIdentifier;
    NSString *connectionName = [identifier stringByAppendingString:@"_Connection"];
    IMKServer *server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:identifier];

    initPreference();
    sharedCandidates = [[CandidatePanel alloc] init];
    [sharedCandidates setGridLayout:[preference boolForKey:@"useGridCandidatePanel"]];

    engine = [ConversionEngine sharedEngine];

    rimeEngine = [RimeEngine sharedEngine];
    NSString *sharedDataDir = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"rime-data"];
    NSString *userDataDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/hallelujah/rime"];
    [rimeEngine startWithSharedDataDir:sharedDataDir userDataDir:userDataDir];

    [[NSBundle mainBundle] loadNibNamed:@"PreferencesMenu" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[WebServer sharedServer] start];

    [[NSApplication sharedApplication] run];
    [rimeEngine shutdown];
    return 0;
}
