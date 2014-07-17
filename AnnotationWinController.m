#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@implementation AnnotationWinController

+ (id)sharedController{
    return sharedController;
}


- (void)awakeFromNib{
    sharedController = self;
}

- (void)showWindow:(NSRect)rect level:(CGWindowLevel)level{
    [panel setFrameOrigin:rect.origin];
   
    level = level + 1;
    NSLog(@"level is:%d",level);
    NSLog(@"NSStatusWindowLevel: %d,NSFloatingWindowLevel:%d)",NSStatusWindowLevel,NSFloatingWindowLevel);//kUtilityWindowClass 8
    [panel orderFront:nil];
    [panel setLevel:level];
    
    [panel setAutodisplay:YES];
    [panel makeKeyWindow];
}

- (void)hideWindow{
    [panel orderOut:nil];
}

- (void)setAnnotation:(NSString *)annotation{
    [self clearAnnotation];
    [view insertText:annotation];
    [view setSelectedRange:NSMakeRange(0,0)];
    [view scrollRangeToVisible:NSMakeRange(0,0)];
}

- (void)clearAnnotation{
    [view setString:@""];
}

- (NSSize)size{
    return [panel frame].size;
}
@end
