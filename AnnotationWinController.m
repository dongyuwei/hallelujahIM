#import "AnnotationWinController.h"


@implementation AnnotationWinController
-(void)awakeFromNib{
//    NSRect annoRect;
//    annoRect.origin.x = 0;
//    annoRect.origin.y = 0;
//    annoRect.size.width = 280;
//    annoRect.size.height = 400;
//    [panel setFrame:annoRect display:YES];
}

- (void)showWindow:(NSRect)rect level:(CGWindowLevel)level{
    [panel setFrameTopLeftPoint:rect.origin];
   
    NSLog(@"rect:%@", CGRectCreateDictionaryRepresentation(rect));
    NSLog(@"AnnotationWin rect:%@", CGRectCreateDictionaryRepresentation([panel frame]));
    
    NSRect e = [[NSScreen mainScreen] frame];
    NSLog(@"mainScreen rect:%@",CGRectCreateDictionaryRepresentation(e));
    
    [panel orderFront:nil];
    [panel setLevel:level];
    
    [panel setAutodisplay:YES];
    [panel makeKeyWindow];
}

- (void)hideWindow{
    [panel orderOut:nil];
}

- (void)setAnnotation:(NSString *)annotation{
    NSLog(@"annotation:%@",annotation);
    [self clearAnnotation];
    [view insertText:annotation];
    [view setSelectedRange:NSMakeRange(0,0)];
    [view scrollRangeToVisible:NSMakeRange(0,0)];
}

- (void)clearAnnotation{
    [view setString:@""];
}

@end
