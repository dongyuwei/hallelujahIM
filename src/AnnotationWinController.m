#import "AnnotationWinController.h"

static const CGFloat kCornerRadius = 6;

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
@property(retain, nonatomic) IBOutlet NSPanel *panel;
@property(retain, nonatomic) IBOutlet NSTextField *view;
@end

@implementation AnnotationWinController
@synthesize view;
@synthesize panel;

+ (AnnotationWinController *)sharedController {
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
    // Match the candidate panel: dark background, light text, rounded corners.
    (self.panel).backgroundColor = [NSColor clearColor];
    (self.panel).opaque = NO;
    NSView *contentView = (self.panel).contentView;
    contentView.wantsLayer = YES;
    contentView.layer.cornerRadius = kCornerRadius;
    contentView.layer.backgroundColor =
        [NSColor colorWithCalibratedRed:0x1B / 255.0 green:0x1B / 255.0 blue:0x1B / 255.0 alpha:1.0].CGColor;
    contentView.layer.masksToBounds = YES;
    [self.view setTextColor:[NSColor colorWithCalibratedRed:0xFC / 255.0 green:0xFC / 255.0 blue:0xFC / 255.0 alpha:1.0]];
    [self.view setDrawsBackground:NO];
    [self performSelector:@selector(hideWindow) withObject:nil afterDelay:0.01];
    // [self showWindow:NSMakePoint(10, self.height + 10)]; //for dev debug
}

- (void)setWindowHeight:(CGFloat)height {
    NSRect panelFrame = self.panel.frame;
    panelFrame.size.height = height;
    [self.panel setFrame:panelFrame display:NO];
    NSRect viewFrame = self.view.frame;
    viewFrame.size.height = height;
    self.view.frame = viewFrame;
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
