#import "FMDB.h"
#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <MDCDamerauLevenshtein/MDCDamerauLevenshtein.h>

@interface ConversionEngine : NSObject

+ (instancetype)sharedEngine;

// Blocks until the background dictionary preload has finished. The app never
// needs this - lookups simply skip a dictionary that is not loaded yet - but
// tests use it to get deterministic state.
- (void)waitForPreparedData;

- (NSMutableArray *)wordsStartsWith:(NSString *)prefix;
- (NSString *)phonexEncode:(NSString *)word;
- (NSArray *)getTranslations:(NSString *)word;
- (NSString *)getPhoneticSymbolOfWord:(NSString *)candidateString;
- (NSString *)getAnnotation:(NSString *)word;
- (NSArray *)sortByDamerauLevenshteinDistance:(NSArray *)original inputText:(NSString *)text;
- (NSArray *)getSuggestionOfSpellChecker:(NSString *)buffer;
- (NSArray *)getCandidates:(NSString *)originalInput;
- (NSDictionary *)getPhonexEncodedWords;

- (NSDictionary *)allSubstitutions;
- (void)addSubstitution:(NSString *)key value:(NSString *)value;
- (void)removeSubstitution:(NSString *)key;

@property NSDictionary *substitutions;
@property NSDictionary *phonexEncoded;
@property JSValue *phonexEncoder;

@end
