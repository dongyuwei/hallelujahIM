#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

#import "ConversionEngine.h"

@class MarkedTextState;
@class PinyinCandidateRows;

// The three input modes the right-Command key cycles through, in cycle order
// (each value one step further than the previous): intelligent English ->
// pinyin (skipped unless the enablePinyinInput preference is on) ->
// traditional English.
typedef NS_ENUM(NSInteger, InputMode) {
    InputModeHallelujahEnglish = 0, // intelligent English candidates
    InputModePinyin = 1,            // Rime-driven Chinese composition
    InputModeRawEnglish = 2,        // keys pass straight through to the app
};

@interface InputController : IMKInputController {
    NSMutableString *_composedBuffer;
    NSMutableString *_originalBuffer;
    NSInteger _insertionIndex;
    NSMutableArray *_candidates;
    InputMode _inputMode;
    NSUInteger _rimeSession;   // RimeSessionId, 0 when no session yet
    NSInteger _panelHighlight; // highlighted candidate row
    // Row model the pinyin panel rows came from; nil outside pinyin mode. Its
    // rows are _candidates; it owns where the raw-input row sits.
    PinyinCandidateRows *_pinyinRows;
    id _currentClient;
    NSUInteger _lastModifiers[2];
    NSEventType _lastEventTypes[2];
    // Marked text last handed to the client; see MarkedTextState.
    MarkedTextState *_markedText;
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
