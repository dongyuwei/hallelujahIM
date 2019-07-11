#import "WebServer.h"
#import "marisa.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

const NSString *kConnectionName = @"Hallelujah_1_Connection";
IMKServer *server;
IMKCandidates *sharedCandidates;
marisa::Trie trie;
NSDictionary *wordsWithFrequencyAndTranslation;
NSDictionary *substitutions;
NSDictionary *pinyinDict;
NSDictionary *phonexEncoded;
NSUserDefaults *preference;

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

NSDictionary *deserializeJSON(NSString *path) {
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [inputStream open];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithStream:inputStream options:nil error:nil];

    [inputStream close];
    return dict;
}

NSDictionary *getWordsWithFrequencyAndTranslation() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation_and_ipa" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getPinyinData() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cedict" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getPhonexEncodedWords() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"phonex_encoded_words" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getUserDefinedSubstitutions() {
    NSString *path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/.you_expand_me.json"];
    return deserializeJSON(path);
}

void loadTrie() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"google_227800_words" ofType:@"bin"];
    const char *path2 = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
    trie.load(path2);
}

int main(int argc, char *argv[]) {
    if (argc > 1 && !strcmp("--install", argv[1])) {
        registerInputSource();
        deactivateInputSource();
        activateInputSource();
        return 0;
    }

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:(NSString *)kConnectionName bundleIdentifier:identifier];

    sharedCandidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];

    if (!sharedCandidates) {
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }

    loadTrie();

    wordsWithFrequencyAndTranslation = getWordsWithFrequencyAndTranslation();
    substitutions = getUserDefinedSubstitutions();
    pinyinDict = getPinyinData();
    phonexEncoded = getPhonexEncodedWords();

    [[NSBundle mainBundle] loadNibNamed:@"AnnotationWindow" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[NSBundle mainBundle] loadNibNamed:@"PreferencesMenu" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[WebServer sharedServer] start];

    [[NSApplication sharedApplication] run];
    return 0;
}
