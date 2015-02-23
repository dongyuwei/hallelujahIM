//
//  LDBSnapshot.h
//
//  Copyright 2013 Storm Labs.
//  See LICENCE for details.
//

#import <Foundation/Foundation.h>
#import "LevelDB.h"

@class LevelDB;

@interface LDBSnapshot : NSObject 

@property (nonatomic, readonly, assign) LevelDB * db;

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


/**
 Return an array containing all the keys of the database
 
 @warning This shouldn't be used with very large databases, since every key will be stored in memory
 */
- (NSArray *)allKeys;

/**
 Return an array of key for which the value match the given predicate
 
 @param predicate A `NSPredicate` instance tested against the database's values to retrieve the corresponding keys
 */
- (NSArray *)keysByFilteringWithPredicate:(NSPredicate *)predicate;

/**
 Return a dictionary with all key-value pairs, where values match the given predicate
 
 @param predicate A `NSPredicate` instance tested against the database's values to retrieve the corresponding key-value pairs
 */
- (NSDictionary *)dictionaryByFilteringWithPredicate:(NSPredicate *)predicate;

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