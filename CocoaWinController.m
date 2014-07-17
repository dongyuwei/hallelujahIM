#import "CocoaWinController.h"
#import "AnnotationWinController.h"

static CocoaWinController *sharedController;

@implementation CocoaWinController

+ (id)sharedController{
    if (!sharedController){
        [[self alloc] init];
    }
    return sharedController;
}

- (id)init{
    if (sharedController){
        return sharedController;
    }
    
    self = [super init];
    
    if (![NSBundle loadNibNamed:@"Window" owner:self]) {
        NSLog(@"failed to load CocoaWindow nib");
        [self release];
        return nil;
    }
    sharedController = self;
    return self;
}

- (void)dealloc{
    sharedController = nil;
    
    [super dealloc];
}

- (void)showAnnotation:(NSRect)rect annotation:(NSString *)annotation level:(CGWindowLevel)level{
    NSLog(@"rect is: %@  annotation:%@",NSStringFromRect(rect),annotation);
    AnnotationWinController *annotationWin = [AnnotationWinController sharedController];
    
    [annotationWin setAnnotation:annotation];
    [annotationWin showWindow:rect level:level];
}

@end
