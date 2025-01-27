#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

#import "AnnotationWinController.h"
#import "ConversionEngine.h"

@interface InputController : IMKInputController {
    NSMutableString *_sentenceBuffer;
    NSMutableString *_composedBuffer;
    NSMutableString *_originalBuffer;
    NSInteger _insertionIndex;
    NSInteger _currentCandidateIndex;
    NSMutableArray *_candidates;
    BOOL _defaultEnglishMode;
    id _currentClient;
    NSUInteger _lastModifiers[2];
    NSEventType _lastEventTypes[2];
    AnnotationWinController *_annotationWin;
}

- (NSMutableString *)sentenceBuffer;
- (void)setSentenceBuffer:(NSString *)string;

- (NSMutableString *)composedBuffer;
- (void)setComposedBuffer:(NSString *)string;
- (NSMutableString *)originalBuffer;
- (void)originalBufferAppend:(NSString *)string client:(id)sender;
- (void)setOriginalBuffer:(NSString *)string;

@end
