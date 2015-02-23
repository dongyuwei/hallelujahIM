//
//  WriteBatch.mm
//
//  Copyright 2013 Storm Labs. 
//  See LICENCE for details.
//

#import <leveldb/db.h>
#import <leveldb/write_batch.h>

#import "LDBWriteBatch.h"
#include "Common.h"

@interface LDBWritebatch () {
    leveldb::WriteBatch _writeBatch;
    id _db;
}

@property (readonly) leveldb::WriteBatch writeBatch;

@end

@implementation LDBWritebatch {
    dispatch_queue_t _serial_queue;
}

@synthesize writeBatch = _writeBatch;
@synthesize db = _db;

+ (instancetype) writeBatchFromDB:(id)db {
    id wb = [[[self alloc] init] autorelease];
    ((LDBWritebatch *)wb)->_db = [db retain];
    return wb;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        _serial_queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)dealloc {
    if (_serial_queue) {
        dispatch_release(_serial_queue);
        _serial_queue = nil;
    }
    if (_db) {
        [_db release];
        _db = nil;
    }
    [super dealloc];
}

- (void) removeObjectForKey:(id)key {
    AssertKeyType(key);
    leveldb::Slice k = KeyFromStringOrData(key);
    dispatch_sync(_serial_queue, ^{
        _writeBatch.Delete(k);
    });
}
- (void) removeObjectsForKeys:(NSArray *)keyArray {
    [keyArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeObjectForKey:obj];
    }];
}
- (void) removeAllObjects {
    [_db enumerateKeysUsingBlock:^(LevelDBKey *key, BOOL *stop) {
        [self removeObjectForKey:NSDataFromLevelDBKey(key)];
    }];
}

- (void) setData:(NSData *)data forKey:(id)key {
    AssertKeyType(key);
    dispatch_sync(_serial_queue, ^{
        leveldb::Slice lkey = KeyFromStringOrData(key);
        _writeBatch.Put(lkey, SliceFromData(data));
    });
}
- (void) setObject:(id)value forKey:(id)key {
    AssertKeyType(key);
    dispatch_sync(_serial_queue, ^{
        leveldb::Slice k = KeyFromStringOrData(key);
        LevelDBKey lkey = GenericKeyFromSlice(k);
        
        NSData *data = ((LevelDB *)_db).encoder(&lkey, value);
        leveldb::Slice v = SliceFromData(data);
        
        _writeBatch.Put(k, v);
    });
}
- (void) setValue:(id)value forKey:(NSString *)key {
    [self setObject:value forKey:key];
}
- (void) addEntriesFromDictionary:(NSDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setObject:obj forKey:key];
    }];
}

- (void) apply {
    [_db applyWritebatch:self];
}

@end