#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface PasswordManager : NSObject

+ (void)storePasswordForServiceName:(NSString *)serviceName
                    withAccountName:(NSString *)accountName
                        andPassword:(NSString *)password;

+ (NSString *)getPasswordFromServiceName:(NSString *)serviceName
                          forAccountName:(NSString *)accountName;

@end