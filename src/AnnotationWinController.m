#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
@property(retain, nonatomic) IBOutlet NSPanel *panel;
@property(retain, nonatomic) IBOutlet NSTextField *view;
@end

@implementation AnnotationWinController
@synthesize view;
@synthesize panel;

+ (id)sharedController {
    return sharedController;
}

- (void)awakeFromNib {
    sharedController = self;
    self.width = 160;
    // self.height = 282;

    [[self panel] orderFront:nil];
    [[self panel] setLevel:CGShieldingWindowLevel() + 1];

    // Make sure panel can float over full screen apps
    self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    [self.panel setStyleMask:NSWindowStyleMaskBorderless];

    [self performSelector:@selector(hideWindow) withObject:nil afterDelay:0.01];
    // [self showWindow:NSMakePoint(10, self.height + 10)]; //for dev debug
}

- (void)showWindow:(NSPoint)origin {
    [[self panel] setFrameTopLeftPoint:origin];

    self.panel.alphaValue = 1;
}

- (void)hideWindow {
    self.panel.alphaValue = 0;
}

- (void)setAnnotation:(NSString *)annotation {
    [self.view setStringValue:annotation];
}

@end
