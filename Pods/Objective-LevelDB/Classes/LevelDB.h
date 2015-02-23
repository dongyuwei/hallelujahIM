//
//  LevelDB.h
//
//  Copyright 2011 Pave Labs. 
//  See LICENCE for details.
//

#import <Foundation/Foundation.h>

@class LDBSnapshot;
@class LDBWritebatch;

typedef struct LevelDBOptions {
    BOOL createIfMissing ;
    BOOL createIntermediateDirectories;
    BOOL errorIfExists   ;
    BOOL paranoidCheck   ;
    BOOL compression     ;
    int  filterPolicy    ;
    size_t cacheSize;
} LevelDBOptions;

typedef struct {
    const char * data;
    NSUInteger   length;
} LevelDBKey;

typedef NSData * (^LevelDBEncoderBlock) (LevelDBKey * key, id object);
typedef id       (^LevelDBDecoderBlock) (LevelDBKey * key, id data);

typedef void     (^LevelDBKeyBlock)     (LevelDBKey * key, BOOL *stop);
typedef void     (^LevelDBKeyValueBlock)(LevelDBKey * key, id value, BOOL *stop);

typedef id       (^LevelDBValueGetterBlock)  (void);
typedef void     (^LevelDBLazyKeyValueBlock) (LevelDBKey * key, LevelDBValueGetterBlock lazyValue, BOOL *stop);

FOUNDATION_EXPORT NSString * const kLevelDBChangeType;
FOUNDATION_EXPORT NSString * const kLevelDBChangeTypePut;
FOUNDATION_EXPORT NSString * const kLevelDBChangeTypeDelete;
FOUNDATION_EXPORT NSString * const kLevelDBChangeValue;
FOUNDATION_EXPORT NSString * const kLevelDBChangeKey;

#ifdef __cplusplus
extern "C" {
#endif
    
NSString * NSStringFromLevelDBKey(LevelDBKey * key);
NSData   * NSDataFromLevelDBKey  (LevelDBKey * key);

#ifdef __cplusplus
}
#endif

@interface LevelDB : NSObject

///------------------------------------------------------------------------
/// @name A LevelDB object, used to query to the database instance on disk
///------------------------------------------------------------------------

/**
 The path of the database on disk
 */
@property (nonatomic, retain) NSString *path;

/**
 The name of the database.
 */
@property (nonatomic, retain) NSString *name;

/**
 A boolean value indicating whether write operations should be synchronous (flush to disk before returning).
 */
@property (nonatomic) BOOL safe;

/**
 A boolean value indicating whether read operations should try to use the configured cache (defaults to true).
 */
@property (nonatomic) BOOL useCache;

/**
 A boolean readonly value indicating whether the database is closed or not.
 */
@property (readonly) BOOL closed;

/**
 The data encoding block.
 */
@property (nonatomic, copy) LevelDBEncoderBlock encoder;

/**
 The data decoding block.
 */
@property (nonatomic, copy) LevelDBDecoderBlock decoder;

/**
 A class method that returns a LevelDBOptions struct, which can be modified to finetune leveldb
 */
+ (LevelDBOptions) makeOptions;

/**
 A class method that returns an autoreleased instance of LevelDB with the given name, inside the Library folder
 
 @param name The database's filename
 */
+ (id) databaseInLibraryWithName:(NSString *)name;

/**
 A class method that returns an autoreleased instance of LevelDB with the given name and options, inside the Library folder
 
 @param name The database's filename
 @param opts A LevelDBOptions struct with options for fine tuning leveldb
 */
+ (id) databaseInLibraryWithName:(NSString *)name andOptions:(LevelDBOptions)opts;

/**
 Initialize a leveldb instance
 
 @param path The parent directory of the database file on disk
 @param name the filename of the database file on disk
 */
- (id) initWithPath:(NSString *)path andName:(NSString *)name;

/**
 Initialize a leveldb instance
 
 @param path The parent directory of the database file on disk
 @param name the filename of the database file on disk
 @param opts A LevelDBOptions struct with options for fine tuning leveldb
 */
- (id) initWithPath:(NSString *)path name:(NSString *)name andOptions:(LevelDBOptions)opts;


/**
 Delete the database file on disk
 */
- (void) deleteDatabaseFromDisk;

/**
 Close the database.
 
 @warning The instance cannot be used to perform any query after it has been closed.
 */
- (void) close;

#pragma mark - Setters

/**
 Set the value associated with a key in the database
 
 The instance's encoder block will be used to produce a NSData instance from the provided value.
 
 @param value The value to put in the database
 @param key The key at which the value can be found
 */
- (void) setObject:(id)value forKey:(id)key;

/**
 Same as `[self setObject:forKey:]`
 */
- (void) setObject:(id)value forKeyedSubscript:(id)key;

/**
 Same as `[self setObject:forKey:]`
 */
- (void) setValue:(id)value forKey:(NSString *)key ;

/**
 Take all key-value pairs in the provided dictionary and insert them in the database
 
 @param dictionary A dictionary from which key-value pairs will be inserted
 */
- (void) addEntriesFromDictionary:(NSDictionary *)dictionary;

#pragma mark - Write batches

/**
 Return an retained LDBWritebatch instance for this database
 */
- (LDBWritebatch *) newWritebatch;

/**
 Apply the operations from a writebatch into the current database
 */
- (void) applyWritebatch:(LDBWritebatch *)writeBatch;

#pragma mark - Getters

/**
 Return the value associated with a key
 
 @param key The key to retrieve from the database
 */
- (id) objectForKey:(id)key;

/**
 Same as `[self objectForKey:]`
 */
- (id) objectForKeyedSubscript:(id)key;

/**
 Same as `[self objectForKey:]`
 */
- (id) valueForKey:(NSString *)key;

/**
 Return an array containing the values associated with the provided list of keys.
 
 For keys that can't be found in the database, the `marker` value is used in place.
 
 @warning marker should not be `nil`
 
 @param keys The list of keys to fetch from the database
 @param marker The value to associate to missing keys
 */
- (id) objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker;

/**
 Return a boolean value indicating whether or not the key exists in the database
 
 @param key The key to check for existence
 */
- (BOOL) objectExistsForKey:(id)key;

#pragma mark - Removers

/**
 Remove a key (and its associated value) from the database
 
 @param key The key to remove from the database
 */
- (void) removeObjectForKey:(id)key;

/**
 Remove a set of keys (and their associated values) from the database
 
 @param keyArray An array of keys to remove from the database
 */
- (void) removeObjectsForKeys:(NSArray *)keyArray;

/**
 Remove all objects from the database
 */
- (void) removeAllObjects;

/**
 Remove all objects prefixed with a given value (`NSString` or `NSData`)
 
 @param prefix The key prefix used to remove all matching keys (of type `NSString` or `NSData`)
 */
- (void) removeAllObjectsWithPrefix:(id)prefix;

#pragma mark - Selection

/**
 Return an array containing all the keys of the database
 
 @warning This shouldn't be used with very large databases, since every key will be stored in memory
 */
- (NSArray *) allKeys;

/**
 Return an array of key for which the value match the given predicate
 
 @param predicate A `NSPredicate` instance tested against the database's values to retrieve the corresponding keys
 */
- (NSArray *) keysByFilteringWithPredicate:(NSPredicate *)predicate;

/**
 Return a dictionary with all key-value pairs, where values match the given predicate
 
 @param predicate A `NSPredicate` instance tested against the database's values to retrieve the corresponding key-value pairs
 */
- (NSDictionary *) dictionaryByFilteringWithPredicate:(NSPredicate *)predicate;

/**
 Return an retained LDBSnapshot instance for this database
 
 LDBSnapshots are a way to "freeze" the state of the database. Write operation applied to the database after the
 snapshot was taken do not affect the snapshot. Most *read* methods available in the LevelDB class are also
 available in the LDBSnapshot class.
 */
- (LDBSnapshot *) newSnapshot;

#pragma mark - Enumeration

/**
 Enumerate over the keys in the database, in order.
 
 Same as `[self enumerateKeysBackward:FALSE startingAtKey:nil filteredByPredicate:nil andPrefix:nil usingBlock:block]`
 
 @param block The enumeration block used when iterating over all the keys.
 */
- (void) enumerateKeysUsingBlock:(LevelDBKeyBlock)block;

/**
 Enumerate over the keys in the database, in direct or backward order, with some options to control the keys iterated over
 
 @param backward A boolean value indicating whether the enumeration happens in direct or backward order
 @param key (optional) The key at which to start iteration. If the key isn't present in the database, the enumeration starts at the key immediately greater than the provided one. The key can be a `NSData` or `NSString`
 @param predicate A `NSPredicate` instance tested against the values. The iteration block will only be called for keys associated to values matching the predicate. If `nil`, this is ignored.
 @param prefix A `NSString` or `NSData` prefix used to filter the keys. If provided, only the keys prefixed with this value will be iterated over.
 @param block The enumeration block used when iterating over all the keys. It takes two arguments: the first is a pointer to a `LevelDBKey` struct. You can convert this to a `NSString` or `NSData` instance, using `NSDataFromLevelDBKey(LevelDBKey *key)` and `NSStringFromLevelDBKey(LevelDBKey *key)` respectively. The second arguments to the block is a `BOOL *` that can be used to stop enumeration at any time (e.g. `*stop = TRUE;`).
 */
- (void) enumerateKeysBackward:(BOOL)backward
                 startingAtKey:(id)key
           filteredByPredicate:(NSPredicate *)predicate
                     andPrefix:(id)prefix
                    usingBlock:(LevelDBKeyBlock)block;


/**
 Enumerate over the key value pairs in the database, in order.
 
 Same as `[self enumerateKeysAndObjectsBackward:FALSE startingAtKey:nil filteredByPredicate:nil andPrefix:nil usingBlock:block]`
 
 @param block The enumeration block used when iterating over all the key value pairs.
 */
- (void) enumerateKeysAndObjectsUsingBlock:(LevelDBKeyValueBlock)block;

/**
 Enumerate over the keys in the database, in direct or backward order, with some options to control the keys iterated over
 
 @param backward A boolean value indicating whether the enumeration happens in direct or backward order
 @param key (optional) The key at which to start iteration. If the key isn't present in the database, the enumeration starts at the key immediately greater than the provided one. The key can be a `NSData` or `NSString`
 @param predicate A `NSPredicate` instance tested against the values. The iteration block will only be called for keys associated to values matching the predicate. If `nil`, this is ignored.
 @param prefix A `NSString` or `NSData` prefix used to filter the keys. If provided, only the keys prefixed with this value will be iterated over.
 @param block The enumeration block used when iterating over all the keys. It takes three arguments: the first is a pointer to a `LevelDBKey` struct. You can convert this to a `NSString` or `NSData` instance, using `NSDataFromLevelDBKey(LevelDBKey *key)` and `NSStringFromLevelDBKey(LevelDBKey *key)` respectively. The second argument is the value associated with the key. The third arguments to the block is a `BOOL *` that can be used to stop enumeration at any time (e.g. `*stop = TRUE;`).
 */
- (void) enumerateKeysAndObjectsBackward:(BOOL)backward
                                  lazily:(BOOL)lazily
                           startingAtKey:(id)key
                     filteredByPredicate:(NSPredicate *)predicate
                               andPrefix:(id)prefix
                              usingBlock:(id)block;

@end
