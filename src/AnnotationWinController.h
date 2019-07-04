#import <Cocoa/Cocoa.h>

@interface AnnotationWinController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
}

@property int width;
@property int height;
@property(nonatomic, strong) NSMutableArray *translations;

- (void)show:(NSPoint)origin;

- (void)hide;

- (void)setTranslations:(NSMutableArray *)translations;

+ (id)sharedController;

@end
