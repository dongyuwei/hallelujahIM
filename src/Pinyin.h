#import <Foundation/Foundation.h>

@interface Pinyin : NSObject

@property (nonatomic, strong) NSString *py;
@property (nonatomic, strong) NSString *hz;
@property (nonatomic, strong) NSString *abbr;
@property (nonatomic, assign) NSInteger freq;

@end
