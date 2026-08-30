#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

#import "AnnotationWinController.h"
#import "ConversionEngine.h"

@interface InputController : IMKInputController {
    NSMutableString *_composedBuffer;
    NSMutableString *_originalBuffer;
    NSInteger _insertionIndex;
    NSInteger _currentCandidateIndex;
    NSMutableArray *_candidates;
    BOOL _defaultEnglishMode;
    BOOL _pinyinMode;
    NSUInteger _rimeSession;                              // RimeSessionId, 0 when no session yet
    NSInteger _panelHighlight;                            // candidate row mirrored from Rime's highlight
    NSInteger _mixedEnglishCount;                         // rows of English candidates at the top of a mixed-mode page
    NSMutableArray<NSString *> *_rimePageCandidates;      // raw Rime page, kept apart from the combined list
    NSMutableArray<NSNumber *> *_mixedChineseRimeIndexes; // Rime page index shown on each Chinese row
    id _currentClient;
    NSUInteger _lastModifiers[2];
    NSEventType _lastEventTypes[2];
    AnnotationWinController *_annotationWin;
    NSMutableArray<NSString *> *_recentWords;
}

- (NSMutableString *)composedBuffer;
- (void)setComposedBuffer:(NSString *)string;
- (NSMutableString *)originalBuffer;
- (void)originalBufferAppend:(NSString *)string client:(id)sender;
- (void)setOriginalBuffer:(NSString *)string;
- (NSString *)recentContext;
- (void)recordCommittedWord:(NSString *)word;
- (void)resetContext;
- (void)showIMEPreferences:(id)sender;
- (void)clickAbout:(id)sender;
- (void)clickUpgrade:(id)sender;

@end
