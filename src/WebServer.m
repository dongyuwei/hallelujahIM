#import "WebServer.h"
#import <GCDWebServer.h>
#import <GCDWebServerDataResponse.h>
#import <GCDWebServerURLEncodedFormRequest.h>

extern NSUserDefaults *preference;

void initPreference() {
    preference = [NSUserDefaults standardUserDefaults];
    if ([preference objectForKey:@"showTranslation"] == nil) {
        [preference setBool:YES forKey:@"showTranslation"];
    }
}

NSDictionary *getDictionaryRepresentationOfPreference() {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    BOOL showTranslation = [preference boolForKey:@"showTranslation"];
    [dict setObject:[NSNumber numberWithBool:showTranslation] forKey:@"showTranslation"];
    return dict;
}

@interface WebServer ()

@property(nonatomic, strong) GCDWebServer *server;

@end

@implementation WebServer

static int port = 62718;

+ (instancetype)sharedServer {
    static WebServer *server = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        server = [[WebServer alloc] init];
    });
    return server;
}

- (void)start {
    if (self.server) {
        return;
    }
    initPreference();

    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addGETHandlerForBasePath:@"/"
                          directoryPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"web"]
                          indexFilename:nil
                               cacheAge:3600
                     allowRangeRequests:YES];

    [webServer addHandlerForMethod:@"GET"
                              path:@"/preference"
                      requestClass:[GCDWebServerRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          return [GCDWebServerDataResponse responseWithJSONObject:getDictionaryRepresentationOfPreference()];
                      }];

    [webServer addHandlerForMethod:@"POST"
                              path:@"/preference"
                      requestClass:[GCDWebServerURLEncodedFormRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          NSDictionary *data = [(GCDWebServerDataRequest *)request jsonObject];
                          bool showTranslation = [[data objectForKey:@"showTranslation"] boolValue];
                          [preference setBool:showTranslation forKey:@"showTranslation"];
                          return [GCDWebServerDataResponse responseWithJSONObject:data];
                      }];
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithInt:port] forKey:GCDWebServerOption_Port];
    [options setObject:@YES forKey:GCDWebServerOption_BindToLocalhost];

    [webServer startWithOptions:options error:nil];
}

@end
