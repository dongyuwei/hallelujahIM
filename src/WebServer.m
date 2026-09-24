#import "WebServer.h"
#import "CandidatePanel.h"
#import "ConversionEngine.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerURLEncodedFormRequest.h"
#import "PinyinCandidateRows.h"

extern NSUserDefaults *preference;
extern ConversionEngine *engine;
extern CandidatePanel *sharedCandidates;
// Defined in main.mm; starts librime when the pinyin preference is on.
extern void startRimeEngine(void);

NSString *TRANSLATION_KEY = @"showTranslation";
NSString *COMMIT_WORD_WITH_SPACE_KEY = @"commitWordWithSpace";
NSString *GRID_CANDIDATE_COLUMNS_KEY = @"gridCandidateColumns";
NSString *PINYIN_INPUT_ENABLED_KEY = @"enablePinyinInput";
NSString *PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY = @"pinyinRawInputCandidatePosition";

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
    // No caching: the preference page ships inside the app bundle, so a stale
    // cached copy shows settings that the installed build no longer has.
    [webServer addGETHandlerForBasePath:@"/"
                          directoryPath:[NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].resourcePath, @"web"]
                          indexFilename:nil
                               cacheAge:0
                     allowRangeRequests:YES];

    [webServer
        addHandlerForMethod:@"GET"
                       path:@"/preference"
               requestClass:[GCDWebServerRequest class]
               processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                   return [GCDWebServerDataResponse responseWithJSONObject:@{
                       TRANSLATION_KEY : @([preference boolForKey:TRANSLATION_KEY]),
                       COMMIT_WORD_WITH_SPACE_KEY : @([preference boolForKey:COMMIT_WORD_WITH_SPACE_KEY]),
                       GRID_CANDIDATE_COLUMNS_KEY : @([preference integerForKey:GRID_CANDIDATE_COLUMNS_KEY]),
                       PINYIN_INPUT_ENABLED_KEY : @([preference boolForKey:PINYIN_INPUT_ENABLED_KEY]),
                       PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY : @([preference integerForKey:PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY]),
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

                          bool enablePinyinInput = [data[PINYIN_INPUT_ENABLED_KEY] boolValue];
                          [preference setBool:enablePinyinInput forKey:PINYIN_INPUT_ENABLED_KEY];

                          // Clamped into the valid range (1-5); a missing key
                          // keeps the stored value.
                          NSInteger pinyinRawInputCandidatePosition = [data[PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY] integerValue];
                          if (data[PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY] == nil) {
                              pinyinRawInputCandidatePosition = [preference integerForKey:PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY];
                          }
                          pinyinRawInputCandidatePosition = [PinyinCandidateRows clampedPosition:pinyinRawInputCandidatePosition];
                          [preference setInteger:pinyinRawInputCandidatePosition forKey:PINYIN_RAW_INPUT_CANDIDATE_POSITION_KEY];

                          // Turning pinyin on starts librime, which the launch
                          // path only did when the preference was already set;
                          // main queue, same as the launch path.
                          if (enablePinyinInput) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  startRimeEngine();
                              });
                          }

                          // Clamped by CandidatePanelState; read the accepted value back.
                          NSInteger gridCandidateColumns = [data[GRID_CANDIDATE_COLUMNS_KEY] integerValue];
                          if (data[GRID_CANDIDATE_COLUMNS_KEY] == nil) {
                              gridCandidateColumns = [preference integerForKey:GRID_CANDIDATE_COLUMNS_KEY];
                          }
                          // The custom panel rebuilds its window when the
                          // column count changes; window operations are
                          // main-thread-only, and the web server handler runs on a
                          // GCD queue, so hop over first.
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [sharedCandidates setGridColumns:gridCandidateColumns];
                              [preference setInteger:[sharedCandidates gridColumns] forKey:GRID_CANDIDATE_COLUMNS_KEY];
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
