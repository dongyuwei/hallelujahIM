#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
    @property (retain, nonatomic) IBOutlet NSPanel *panel;
    @property (retain, nonatomic) IBOutlet NSTextView *view;
@end

@implementation AnnotationWinController
@synthesize view;
@synthesize panel;

+ (id)sharedController
{
    return sharedController;
}

-(void)awakeFromNib{
    sharedController = self;
    [[self panel] setStyleMask:NSBorderlessWindowMask];
    [self hideWindow];
}

- (void)showWindow:(NSPoint)origin {
    NSSize size;
    size.width = 300;
    size.height = 400;
    [[self panel] setContentSize: size];
    [[self panel] setAlphaValue: 0.9];

    [[self panel] setFrameTopLeftPoint: origin];
    [[self panel] orderFront:nil];
    [[self panel] setLevel: CGShieldingWindowLevel() + 1];
    [[self panel] setAutodisplay:YES];
}

- (void)hideWindow{
//    [[self panel] orderOut:nil];
    NSRect rect;
    rect.size.width = 0;
    rect.size.height = 0;
    [[self panel] setFrame:rect display:NO];
}

- (void)setAnnotation:(NSString *)annotation{
    [[self view] setString:annotation];
}

@end
