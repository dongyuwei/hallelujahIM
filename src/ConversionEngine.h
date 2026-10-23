#import "FMDB.h"
#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <MDCDamerauLevenshtein/MDCDamerauLevenshtein.h>

@interface ConversionEngine : NSObject

+ (instancetype)sharedEngine;

// Schema version the bundled database is expected to carry, and the version
// stored in the database at `path` (-1 when it cannot be read). -initDatabase
// replaces the copy in Application Support whenever the two disagree.
//
// Exposed because CI always starts without a copy and therefore only exercises
// the "no copy yet, copy it" path: a mismatch between the bundled database and
// this constant would otherwise go unnoticed until an existing install either
// re-copied the database on every launch or silently lost its pinyin rows.
+ (NSInteger)expectedDatabaseSchemaVersion;
+ (NSInteger)schemaVersionOfDatabaseAtPath:(NSString *)path;

// Blocks until the background dictionary preload has finished. The app never
// needs this - lookups simply skip a dictionary that is not loaded yet - but
// tests use it to get deterministic state.
- (void)waitForPreparedData;

- (NSMutableArray *)wordsStartsWith:(NSString *)prefix;
- (NSMutableArray *)wordsStartsWith:(NSString *)prefix limit:(NSUInteger)limit;

// Up to three English prefix completions for pinyin-mode letters that cannot
// be complete pinyin (see PinyinSegmenter), so the pinyin panel can put
// English first; the typed word itself is offered first when it is a
// dictionary word, so space never commits a longer completion. Typos with no
// prefix match get nothing here; see spellingSuggestionsForNonPinyinInput:.
// Input shorter than four letters, or non-letter input, gets nothing: short
// strings are too ambiguous (every sh- pinyin start passes through them) and
// their prefix ranges cost milliseconds to scan. The typed case is preserved
// (Hello -> Hello, Hellos).
- (NSArray<NSString *> *)englishCandidatesForNonPinyinInput:(NSString *)input;

// Spelling suggestions for the same gated inputs, ranked by edit distance
// (conectivity -> connectivity), but only from five letters on: a guess is
// weak evidence of English, and Rime's abbreviations match almost any letters
// (including typos), so waiting for Rime to come up empty never happens. Most
// Chinese abbreviations are shorter than five letters (zme/dagn stay
// Chinese-first); longer shorthands and dropped-letter typos (shenm,
// weishenm) can still surface English rows, which is a known trade-off. The
// typed case is preserved on prefix-shaped guesses.
- (NSArray<NSString *> *)spellingSuggestionsForNonPinyinInput:(NSString *)input;

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
