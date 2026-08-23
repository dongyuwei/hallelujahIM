#import "FMDB.h"
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
- (NSArray *)predictNextWordsForContext:(NSString *)context maxResults:(NSInteger)max;
- (NSArray *)predictNextWordsForContext:(NSString *)context prefixFilter:(NSString *)prefix maxResults:(NSInteger)max;
- (NSArray *)fetchHanZiByPinyinWithPrefix:(NSString *)prefix;
- (NSDictionary *)getPinyinData;
- (NSDictionary *)getPhonexEncodedWords;

- (NSDictionary *)allSubstitutions;
- (void)addSubstitution:(NSString *)key value:(NSString *)value;
- (void)removeSubstitution:(NSString *)key;

@property NSDictionary *substitutions;
@property NSDictionary *pinyinDict;
@property NSDictionary *phonexEncoded;
@property JSValue *phonexEncoder;

@end
