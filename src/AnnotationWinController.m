#import "AnnotationWinController.h"

static AnnotationWinController *sharedController;

@interface AnnotationWinController ()
@property(retain, nonatomic) IBOutlet NSPanel *panel;
@property(retain, nonatomic) IBOutlet NSTableView *tableView;
@end

@implementation AnnotationWinController
@synthesize tableView;
@synthesize panel;

+ (id)sharedController {
    return sharedController;
}

- (void)awakeFromNib {
    sharedController = self;
    self.width = 200;
    self.height = 280;
    [[self panel] setStyleMask:NSWindowStyleMaskBorderless];
    [[self panel] setOpaque:NO];
    [[self panel] setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.0]];
    [self hide];
}

- (void)show:(NSPoint)origin {
    NSLog(@"halle 222 showWindow, origin:%@, translations:%@", NSStringFromPoint(origin) , self.translations);
    NSSize size;
    size.width = self.width;
    size.height = self.height;
    [[self panel] setMinSize:size];
    [[self panel] setContentSize:size];
    [[self panel] setAlphaValue:0.9];

    [[self panel] setFrameTopLeftPoint:origin];
    [[self panel] orderFront:nil];
    [[self panel] setLevel:CGShieldingWindowLevel() + 1];
    [[self panel] setAutodisplay:YES];
}

- (void)hide {
    NSRect rect;
    rect.size.width = 0;
    rect.size.height = 0;
    [[self panel] setFrame:rect display:NO];
}

- (void)setTranslations:(NSMutableArray *)translations {
    NSLog(@"halle 111 setTranslations,%@ ", translations);
    self.translations = translations;
    //    [self.tableView reloadData];
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.translations.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.identifier isEqualToString:@"translation"]) {
        return [self.translations objectAtIndex:row];
    }
}

#pragma mark - Table View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {

    NSTableView *tableView = notification.object;
    NSLog(@"User has selected row %ld", (long)tableView.selectedRow);
}

@end
