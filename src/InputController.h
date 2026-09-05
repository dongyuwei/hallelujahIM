#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

#import "ConversionEngine.h"

@interface InputController : IMKInputController {
    NSMutableString *_composedBuffer;
    NSMutableString *_originalBuffer;
    NSInteger _insertionIndex;
    NSInteger _currentCandidateIndex;
    NSMutableArray *_candidates;
    BOOL _defaultEnglishMode;
    BOOL _pinyinMode;
    NSUInteger _rimeSession;                          // RimeSessionId, 0 when no session yet
    NSInteger _panelHighlight;                        // candidate row mirrored from Rime's highlight
    BOOL _lastCommittedWasChinese;                    // drives mixed-mode candidate ordering
    NSMutableArray<NSString *> *_rimePageCandidates;  // raw Rime page, kept apart from the combined list
    NSMutableArray<NSNumber *> *_mixedRowIsEnglish;   // per mixed-mode row: YES = English candidate
    NSMutableArray<NSNumber *> *_mixedRowRimeIndexes; // per mixed-mode row: Rime page index (NSNotFound for English)
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
