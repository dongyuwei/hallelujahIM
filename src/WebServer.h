#import <Foundation/Foundation.h>

@interface WebServer : NSObject

+ (instancetype)sharedServer;

- (void)start;

@end
