#import "CandidatePanel.h"
#import "ConversionEngine.h"
#import "InputApplicationDelegate.h"
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
    NSDictionary *defaultPrefs = @{
        @"commitWordWithSpace" : @YES,
        @"showTranslation" : @YES,
        @"useGridCandidatePanel" : @YES,
        @"gridCandidateColumns" : @(kCandidateGridDefaultColumns),
        @"enablePinyinInput" : @NO,
        @"pinyinRawInputCandidatePosition" : @(2)
    };
    [preference registerDefaults:defaultPrefs];
}

// Starts librime when the pinyin preference is on; called at launch and again
// from the preference page when pinyin input is turned on later (both paths
// run on the main queue, and every step is idempotent, so they cannot
// interleave or double-start). Defined with C linkage for WebServer.m.
extern "C" void startRimeEngine() {
    if (![preference boolForKey:@"enablePinyinInput"]) {
        return;
    }
    NSString *sharedDataDir = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"rime-data"];
    NSString *userDataDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/hallelujah/rime"];
    [rimeEngine startWithSharedDataDir:sharedDataDir userDataDir:userDataDir];

    // Loading the schema costs ~30 ms on the first session, which otherwise
    // lands on the user's first pinyin keystroke.
    [rimeEngine warmUpSession];
}

int main(int argc, char *argv[]) {
    // Printed on every launch, including --install/--deactivate, so the exact
    // build can be read back from Console.app when a user reports a problem.
    NSLog(@"[Hallelujah] version %@ built %@", [InputApplicationDelegate buildVersion], [InputApplicationDelegate buildDate] ?: @"unknown");

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
    [sharedCandidates setGridColumns:[preference integerForKey:@"gridCandidateColumns"]];
    [sharedCandidates setGridLayout:[preference boolForKey:@"useGridCandidatePanel"]];

    engine = [ConversionEngine sharedEngine];

    rimeEngine = [RimeEngine sharedEngine];
    // Pinyin input is opt-in, so librime is only started when its preference
    // is on. Queued for the moment the run loop starts: no input is being
    // handled yet, so the start cost is invisible.
    dispatch_async(dispatch_get_main_queue(), ^{
        startRimeEngine();
    });

    [[NSBundle mainBundle] loadNibNamed:@"PreferencesMenu" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[WebServer sharedServer] start];

    [[NSApplication sharedApplication] run];
    [rimeEngine shutdown];
    return 0;
}
