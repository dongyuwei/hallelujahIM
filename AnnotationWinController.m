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

    [[self view] setString: @"test"];
    [[self view] setString: @"definition: change | BrE tʃeɪn(d)ʒ, AmE tʃeɪndʒ | A. transitive verb ① (alter by modifying) 改变 gǎibiàn to change [somebody's] mind 使某人改变主意 to change one's ways 换一种生活方式 the road has been changed into a dual carriageway 这条路改成了双向车道 ② (alter by replacement) 替换 tìhuàn (exchange, swap) 交换 jiāohuàn the water in the goldfish bowl should be changed regularly 金鱼缸里的水应当定期更换 the comma had been changed to a full stop 那个逗号改成了句号 they've changed their car for a smaller one 他们换了辆小点的车 to change (one's) clothes 换衣服 huàn yīfu to change places (with [somebody]) （与某人）交换位置 she changed places with her boss for a day 她和老板互换工作一天 to change ends Sport 交换场地 jiāohuàn chǎngdì ③ (put clean nappy on) 给…换尿布 gěi… huàn niàobù ‹baby›④ (accept or take back for exchange) «customer, shop, shopkeeper» 退换 tuìhuàn ‹bought item›can I chan"];
    
    NSRect annoRect;
    annoRect.origin.x = 0;
    annoRect.origin.y = 0;
    annoRect.size.width = 300;
    annoRect.size.height = 400;
    [[self panel] setFrame:annoRect display:YES];
//
//    [self showWindow:annoRect level: CGShieldingWindowLevel() + 1];
}

- (void)showWindow:(NSRect)rect level:(CGWindowLevel)level{
    [[self panel] setFrame:rect display:YES];
//    [panel setFrameTopLeftPoint:rect.origin];
    NSLog(@"window rect:%@", CGRectCreateDictionaryRepresentation(rect));
    [[self panel] orderFront:nil];
    [[self panel] setLevel:level];
    [[self panel] setAutodisplay:YES];
    [[self panel] makeKeyWindow];
}

- (void)hideWindow{
    [[self panel] orderOut:nil];
}

- (void)setAnnotation:(NSString *)annotation{
    NSLog(@"annotation:%@",annotation);
    [self clearAnnotation];
    
    [[self view]  insertText:annotation];
    [[self view]  setSelectedRange:NSMakeRange(0,0)];
    [[self view]  scrollRangeToVisible:NSMakeRange(0,0)];
    
    [[self view] setString:annotation];
    [[self view] displayIfNeeded];
    [[self panel] setViewsNeedDisplay:YES];
}

- (void)clearAnnotation{
    [[self view] setString:@""];
}

@end
