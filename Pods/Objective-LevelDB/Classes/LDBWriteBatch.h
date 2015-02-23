//
//  WriteBatch.h
//
//  Copyright 2013 Storm Labs. 
//  See LICENCE for details.
//

#import <Foundation/Foundation.h>

#import "LevelDB.h"

@interface LDBWritebatch : NSObject

@property (nonatomic, assign) id db;

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
 Set the raw data associated with a key in the database
 
 The instance's encoder block will *not* be used to produce a NSData instance from the provided value.
 
 @param value The raw data value to put in the database
 @param key The key at which the value can be found
 */
- (void) setData:(NSData *)data forKey:(id)key;

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
- (void) setValue:(id)value forKey:(NSString *)key;

/**
 Take all key-value pairs in the provided dictionary and insert them in the database
 
 @param dictionary A dictionary from which key-value pairs will be inserted
 */
- (void) addEntriesFromDictionary:(NSDictionary *)dictionary;

/**
 Apply the write batch to the underlying database
 */
- (void) apply;

@end