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
    self.height = 282;

    [self.panel setStyleMask:NSWindowStyleMaskBorderless];
    [self.panel setOpaque:YES];
    [self performSelector:@selector(hideWindow) withObject:nil afterDelay:0.01];
}

- (void)showWindow:(NSPoint)origin {
    NSSize size;
    size.width = self.width;
    size.height = self.height;
    [[self panel] setMinSize:size];
    [[self panel] setContentSize:size];

    [[self panel] setFrameTopLeftPoint:origin];
    [[self panel] orderFront:nil];
    [[self panel] setLevel:CGShieldingWindowLevel() + 1];
    [[self panel] setAutodisplay:YES];
}

- (void)hideWindow {
    NSRect rect;
    rect.size.width = 0;
    rect.size.height = 0;
    [[self panel] setFrame:rect display:NO];
}

- (void)setAnnotation:(NSString *)annotation {
    [self.view setStringValue:annotation];
}

@end
