#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

#import "ConversionEngine.h"

// The three input modes the right-Command key cycles through.
typedef NS_ENUM(NSInteger, InputMode) {
    InputModeHallelujahEnglish = 0, // intelligent English candidates
    InputModeRawEnglish = 1,        // keys pass straight through to the app
    InputModePinyin = 2,            // Rime-driven Chinese composition
};

@interface InputController : IMKInputController {
    NSMutableString *_composedBuffer;
    NSMutableString *_originalBuffer;
    NSInteger _insertionIndex;
    NSInteger _currentCandidateIndex;
    NSMutableArray *_candidates;
    InputMode _inputMode;
    NSUInteger _rimeSession;   // RimeSessionId, 0 when no session yet
    NSInteger _panelHighlight; // candidate row mirrored from Rime's highlight
    id _currentClient;
    NSUInteger _lastModifiers[2];
    NSEventType _lastEventTypes[2];
}

- (NSMutableString *)composedBuffer;
- (void)setComposedBuffer:(NSString *)string;
- (NSMutableString *)originalBuffer;
- (void)originalBufferAppend:(NSString *)string client:(id)sender;
- (void)setOriginalBuffer:(NSString *)string;
- (void)showIMEPreferences:(id)sender;
- (void)clickAbout:(id)sender;
- (void)clickUpgrade:(id)sender;

@end
