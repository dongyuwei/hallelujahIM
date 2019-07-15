#import "marisa.h"
#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <MDCDamerauLevenshtein/MDCDamerauLevenshtein.h>

@interface ConversionEngine : NSObject

+ (instancetype)sharedEngine;
- (NSMutableArray *)wordsStartsWith:(NSString *)prefix;
- (NSArray *)sortWordsByFrequency:(NSArray *)filtered;
- (NSString *)phonexEncode:(NSString *)word;
- (NSArray *)getTranslations:(NSString *)word;
- (NSString *)getPhoneticSymbolOfWord:(NSString *)candidateString;
- (NSString *)getAnnotation:(NSString *)word;
- (NSArray *)sortByDamerauLevenshteinDistance:(NSArray *)original inputText:(NSString *)text;
- (NSArray *)getSuggestionOfSpellChecker:(NSString *)buffer;
- (NSArray *)getCandidates:(NSString *)originalInput;

@property NSDictionary *wordsWithFrequencyAndTranslation;
@property NSDictionary *substitutions;
@property NSDictionary *pinyinDict;
@property NSDictionary *phonexEncoded;
@property JSValue *phonexEncoder;

@end
