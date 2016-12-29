#import <Cocoa/Cocoa.h>

@interface AnnotationWinController : NSWindowController{
//    IBOutlet NSPanel *panel;
//    IBOutlet NSTextView *view;
}

//@property (retain, nonatomic) IBOutlet NSPanel *panel;
//@property (retain, nonatomic) IBOutlet NSTextView *view;

- (void)showWindow:(NSRect)rect level:(CGWindowLevel)level;

- (void)hideWindow;

- (void)setAnnotation:(NSString *)annotation;

- (void)clearAnnotation;

+ (id)sharedController;


@end
