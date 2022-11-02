#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
@property(retain, nonatomic) IBOutlet NSPanel *panel;
@property(retain, nonatomic) IBOutlet NSTextField *view;
@end

@implementation AnnotationWinController
@synthesize view;
@synthesize panel;

+ (AnnotationWinController*)sharedController {
    return sharedController;
}

- (void)awakeFromNib {
    sharedController = self;
    self.width = 160;
    // self.height = 282;

    [self.panel orderFront:nil];
    (self.panel).level = CGShieldingWindowLevel() + 1;
    // Make sure panel can float over full screen apps
    //  self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    (self.panel).styleMask = NSWindowStyleMaskBorderless;
    [self performSelector:@selector(hideWindow) withObject:nil afterDelay:0.01];
    // [self showWindow:NSMakePoint(10, self.height + 10)]; //for dev debug
}

- (void)showWindow:(NSPoint)origin {
    [self.panel setFrameTopLeftPoint:origin];
    self.panel.alphaValue = 1.0;
    self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
}

- (void)hideWindow {
    self.panel.alphaValue = 0;
    self.panel.collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace;
}

- (void)setAnnotation:(NSString *)annotation {
    (self.view).stringValue = annotation;
}

@end
