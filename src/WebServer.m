#import "WebServer.h"
#import "CandidatePanel.h"
#import "ConversionEngine.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerURLEncodedFormRequest.h"

extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern CandidatePanel *sharedCandidates;

NSString *TRANSLATION_KEY = @"showTranslation";
NSString *COMMIT_WORD_WITH_SPACE_KEY = @"commitWordWithSpace";
NSString *MIXED_INPUT_KEY = @"mixedInput";
NSString *GRID_CANDIDATE_PANEL_KEY = @"useGridCandidatePanel";

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

    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addGETHandlerForBasePath:@"/"
                          directoryPath:[NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].resourcePath, @"web"]
                          indexFilename:nil
                               cacheAge:3600
                     allowRangeRequests:YES];

    [webServer addHandlerForMethod:@"GET"
                              path:@"/preference"
                      requestClass:[GCDWebServerRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          return [GCDWebServerDataResponse responseWithJSONObject:@{
                              TRANSLATION_KEY : @([preference boolForKey:TRANSLATION_KEY]),
                              COMMIT_WORD_WITH_SPACE_KEY : @([preference boolForKey:COMMIT_WORD_WITH_SPACE_KEY]),
                              MIXED_INPUT_KEY : @([preference boolForKey:MIXED_INPUT_KEY]),
                              GRID_CANDIDATE_PANEL_KEY : @([preference boolForKey:GRID_CANDIDATE_PANEL_KEY]),
                          }];
                      }];

    [webServer addHandlerForMethod:@"POST"
                              path:@"/preference"
                      requestClass:[GCDWebServerURLEncodedFormRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          NSDictionary *data = ((GCDWebServerDataRequest *)request).jsonObject;

                          bool showTranslation = [data[TRANSLATION_KEY] boolValue];
                          [preference setBool:showTranslation forKey:TRANSLATION_KEY];

                          bool commitWordWithSpace = [data[COMMIT_WORD_WITH_SPACE_KEY] boolValue];
                          [preference setBool:commitWordWithSpace forKey:COMMIT_WORD_WITH_SPACE_KEY];

                          bool mixedInput = [data[MIXED_INPUT_KEY] boolValue];
                          [preference setBool:mixedInput forKey:MIXED_INPUT_KEY];
                          bool useGridCandidatePanel = [data[GRID_CANDIDATE_PANEL_KEY] boolValue];
                          [preference setBool:useGridCandidatePanel forKey:GRID_CANDIDATE_PANEL_KEY];
                          // The custom panel rebuilds its window when switching layouts;
                          // window operations are main-thread-only, and the web server
                          // handler runs on a GCD queue, so hop over first.
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [sharedCandidates setGridLayout:useGridCandidatePanel];
                          });

                          return [GCDWebServerDataResponse responseWithJSONObject:data];
                      }];

    [webServer addHandlerForMethod:@"GET"
                              path:@"/substitutions"
                      requestClass:[GCDWebServerRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          return [GCDWebServerDataResponse responseWithJSONObject:[engine allSubstitutions]];
                      }];

    [webServer addHandlerForMethod:@"POST"
                              path:@"/substitutions"
                      requestClass:[GCDWebServerDataRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          NSDictionary *data = ((GCDWebServerDataRequest *)request).jsonObject;
                          NSString *key = data[@"key"];
                          NSString *value = data[@"value"];
                          if (key.length > 0 && value.length > 0) {
                              [engine addSubstitution:key value:value];
                          }
                          return [GCDWebServerDataResponse responseWithJSONObject:[engine allSubstitutions]];
                      }];

    [webServer addHandlerForMethod:@"DELETE"
                         pathRegex:@"/substitutions/(.+)"
                      requestClass:[GCDWebServerRequest class]
                      processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                          NSArray *captures = [request attributeForKey:GCDWebServerRequestAttribute_RegexCaptures];
                          NSString *key = captures.firstObject;
                          if (key.length > 0) {
                              [engine removeSubstitution:key];
                          }
                          return [GCDWebServerDataResponse responseWithJSONObject:[engine allSubstitutions]];
                      }];

    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[GCDWebServerOption_Port] = @(port);
    options[GCDWebServerOption_BindToLocalhost] = @YES;

    [webServer startWithOptions:options error:nil];
}

@end
