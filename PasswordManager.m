#import "PasswordManager.h"

@implementation PasswordManager

+ (void)storePasswordForServiceName:(NSString *)serviceName
                              withAccountName:(NSString *)accountName
                                  andPassword:(NSString *)password {
    SecKeychainItemRef item = 0;
    
    SecKeychainFindGenericPassword(
                                   NULL,
                                   [serviceName length],
                                   [serviceName UTF8String],
                                   [accountName length],
                                   [accountName UTF8String],
                                   NULL,
                                   NULL,
                                   &item);
    
    if (item) {
        SecKeychainItemModifyAttributesAndData(
                                               item,
                                               NULL,
                                               [password length],
                                               [password UTF8String]);
    }else{
        SecKeychainAddGenericPassword(
                                      NULL,
                                      (UInt32)serviceName.length,
                                      serviceName.UTF8String,
                                      (UInt32)accountName.length,
                                      accountName.UTF8String,
                                      (UInt32)password.length,
                                      password.UTF8String,
                                      NULL
                                      );
    }
}

+ (NSString *)getPasswordFromServiceName: (NSString *)serviceName
                          forAccountName: (NSString *)accountName {
    
    UInt32 passwordLength = 0;
    void *passwordData = NULL;
    
    SecKeychainFindGenericPassword(
                                   NULL,
                                   (UInt32)serviceName.length,
                                   serviceName.UTF8String,
                                   (UInt32)accountName.length,
                                   accountName.UTF8String,
                                   &passwordLength,
                                   &passwordData,
                                   NULL
                                   );
    
    if (passwordLength > 0) {
        NSString *password = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        
        SecKeychainItemFreeContent(NULL, passwordData);
        
        return password;
    } else {
        return nil;
    }
}

@end