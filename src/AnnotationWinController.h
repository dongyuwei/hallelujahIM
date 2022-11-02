#import <Cocoa/Cocoa.h>

@interface AnnotationWinController : NSWindowController {
}

@property int width;
@property int height;

- (void)showWindow:(NSPoint)origin;

- (void)hideWindow;

- (void)setAnnotation:(NSString *)annotation;

+ (AnnotationWinController*)sharedController;

@end
