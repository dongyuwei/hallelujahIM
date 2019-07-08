#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
@property(retain, nonatomic) IBOutlet NSPanel *panel;
@property(retain, nonatomic) IBOutlet NSTextField *view;
@property(retain, nonatomic) IBOutlet NSTextFieldCell *label;
@end

@implementation AnnotationWinController
@synthesize view;
@synthesize panel;
@synthesize label;

+ (id)sharedController {
    return sharedController;
}

- (void)awakeFromNib {
    sharedController = self;
    self.width = 160;
    self.height = 282;

    [self.panel setStyleMask:NSWindowStyleMaskBorderless];
    [self.panel setOpaque:YES];

    if ([self isDarkMode]) {
        NSColor *bgColor = [NSColor colorWithCalibratedRed:0.133f green:0.152f blue:0.172f alpha:1.0f];
        [self.panel setBackgroundColor:bgColor];
        [self.view setBackgroundColor:bgColor];
        [self.label setBackgroundColor:bgColor];
        NSColor *textColor = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
        [self.view setTextColor:textColor];
        [self.label setTextColor:textColor];
    }

    [self hideWindow];
}

- (BOOL)isDarkMode {
    NSString *interfaceStyle = [NSUserDefaults.standardUserDefaults valueForKey:@"AppleInterfaceStyle"];
    return [interfaceStyle isEqualToString:@"Dark"];
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
