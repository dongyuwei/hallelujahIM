#import "ConversionEngine.h"
#import "WebServer.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

NSUserDefaults *preference;
ConversionEngine *engine;

const NSString *kConnectionName = @"Hallelujah_1_Connection";
IMKCandidates *sharedCandidates;

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
            TISEnableInputSource(inputSource);
            NSLog(@"Enabled input source: %@", sourceID);
            CFBooleanRef isSelectable = (CFBooleanRef)TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable);
            if (CFBooleanGetValue(isSelectable)) {
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
            TISDisableInputSource(inputSource);
            NSLog(@"Disabled input source: %@", sourceID);
        }
    }
    CFRelease(sourceList);
}

void initPreference() {
    preference = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultPrefs = @{@"commitWordWithSpace" : @YES, @"showTranslation" : @YES};
    [preference registerDefaults:defaultPrefs];
}

int main(int argc, char *argv[]) {
    if (argc > 1 && !strcmp("--install", argv[1])) {
        registerInputSource();
        deactivateInputSource();
        activateInputSource();
        return 0;
    }

    NSString *identifier = [NSBundle mainBundle].bundleIdentifier;
    IMKServer *server = [[IMKServer alloc] initWithName:(NSString *)kConnectionName bundleIdentifier:identifier];

    sharedCandidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];

    if (!sharedCandidates) {
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }

    engine = [ConversionEngine sharedEngine];

    [[NSBundle mainBundle] loadNibNamed:@"AnnotationWindow" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[NSBundle mainBundle] loadNibNamed:@"PreferencesMenu" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    initPreference();

    [[WebServer sharedServer] start];

    [[NSApplication sharedApplication] run];
    return 0;
}
