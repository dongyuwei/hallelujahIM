#import <Cocoa/Cocoa.h>

@interface AnnotationWinController : NSWindowController {
}

- (void)showWindow:(NSPoint)origin;

- (void)hideWindow;

- (void)setAnnotation:(NSString *)annotation;

+ (id)sharedController;

@end
