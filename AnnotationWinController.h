#import <Cocoa/Cocoa.h>

@interface AnnotationWinController : NSObject{
    
    IBOutlet NSPanel *panel;
    
    IBOutlet NSTextView *view;
}

- (void)showWindow:(NSRect)rect level:(CGWindowLevel)level;

- (void)hideWindow;

- (void)setAnnotation:(NSString *)annotation;

- (void)clearAnnotation;

- (NSSize)size;

+ (id)sharedController;

@end
