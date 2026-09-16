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
