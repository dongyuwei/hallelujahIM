//
//  LevelDB.m
//
//  Copyright 2011 Pave Labs. All rights reserved. 
//  See LICENCE for details.
//

#import "LevelDB.h"
#import "LDBSnapshot.h"
#import "LDBWriteBatch.h"

#import <leveldb/db.h>
#import <leveldb/options.h>
#import <leveldb/cache.h>
#import <leveldb/filter_policy.h>
#import <leveldb/write_batch.h>

#include "Common.h"

#define MaybeAddSnapshotToOptions(_from_, _to_, _snap_) \
    leveldb::ReadOptions __to_;\
    leveldb::ReadOptions * _to_ = &__to_;\
    if (_snap_ != nil) { \
        _to_->fill_cache = _from_.fill_cache; \
        _to_->snapshot = [_snap_ getSnapshot]; \
    } else \
        _to_ = &_from_;

#define SeekToFirstOrKey(iter, key, _backward_) \
    (key != nil) ? iter->Seek(KeyFromStringOrData(key)) : \
    _backward_ ? iter->SeekToLast() : iter->SeekToFirst()

#define MoveCursor(_iter_, _backward_) \
    _backward_ ? iter->Prev() : iter->Next()

#define EnsureNSData(_obj_) \
    ([_obj_ isKindOfClass:[NSData class]]) ? _obj_ : \
    ([_obj_ isKindOfClass:[NSString class]]) ? [NSData dataWithBytes:[_obj_ cStringUsingEncoding:NSUTF8StringEncoding] \
                                                              length:[_obj_ lengthOfBytesUsingEncoding:NSUTF8StringEncoding]] : nil

#define AssertDBExists(_db_) \
    NSAssert(_db_ != NULL, @"Database reference is not existent (it has probably been closed)");

namespace {
    class BatchIterator : public leveldb::WriteBatch::Handler {
    public:
        void (^putCallback)(const leveldb::Slice& key, const leveldb::Slice& value);
        void (^deleteCallback)(const leveldb::Slice& key);
        
        virtual void Put(const leveldb::Slice& key, const leveldb::Slice& value) {
            putCallback(key, value);
        }
        virtual void Delete(const leveldb::Slice& key) {
            deleteCallback(key);
        }
    };
}

NSString * NSStringFromLevelDBKey(LevelDBKey * key) {
    return [[[NSString alloc] initWithBytes:key->data
                                    length:key->length
                                  encoding:NSUTF8StringEncoding] autorelease];
}
NSData   * NSDataFromLevelDBKey(LevelDBKey * key) {
    return [NSData dataWithBytes:key->data length:key->length];
}

NSString * getLibraryPath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

NSString * const kLevelDBChangeType         = @"changeType";
NSString * const kLevelDBChangeTypePut      = @"put";
NSString * const kLevelDBChangeTypeDelete   = @"del";
NSString * const kLevelDBChangeValue        = @"value";
NSString * const kLevelDBChangeKey          = @"key";

LevelDBOptions MakeLevelDBOptions() {
    return (LevelDBOptions) {true, true, false, false, true, 0, 0};
}

@interface LDBSnapshot ()
+ (id) snapshotFromDB:(LevelDB *)database;
- (const leveldb::Snapshot *) getSnapshot;
@end

@interface LDBWritebatch ()
+ (instancetype) writeBatchFromDB:(id)db;
- (leveldb::WriteBatch) writeBatch;
@end

@interface LevelDB () {
    leveldb::DB * db;
    leveldb::ReadOptions readOptions;
    leveldb::WriteOptions writeOptions;
    const leveldb::Cache * cache;
    const leveldb::FilterPolicy * filterPolicy;
}

@property (nonatomic, readonly) leveldb::DB * db;

@end

@implementation LevelDB

@synthesize db   = db;
@synthesize path = _path;

+ (LevelDBOptions) makeOptions {
    return MakeLevelDBOptions();
}
- (id) initWithPath:(NSString *)path andName:(NSString *)name {
    LevelDBOptions opts = MakeLevelDBOptions();
    return [self initWithPath:path name:name andOptions:opts];
}
- (id) initWithPath:(NSString *)path name:(NSString *)name andOptions:(LevelDBOptions)opts {
    self = [super init];
    if (self) {
        _name = name;
        _path = path;
        
        leveldb::Options options;
        
        options.create_if_missing = opts.createIfMissing;
        options.paranoid_checks = opts.paranoidCheck;
        options.error_if_exists = opts.errorIfExists;
        
        if (!opts.compression)
            options.compression = leveldb::kNoCompression;
        
        if (opts.cacheSize > 0) {
            options.block_cache = leveldb::NewLRUCache(opts.cacheSize);
            cache = options.block_cache;
        } else
            readOptions.fill_cache = false;
        
        if (opts.createIntermediateDirectories) {
            NSString *dirpath = [path stringByDeletingLastPathComponent];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSError *crError;
            
            BOOL success = [fm createDirectoryAtPath:dirpath
                         withIntermediateDirectories:true
                                          attributes:nil
                                               error:&crError];
            if (!success) {
                NSLog(@"Problem creating parent directory: %@", crError);
            }
        }
        
        if (opts.filterPolicy > 0) {
            filterPolicy = leveldb::NewBloomFilterPolicy(opts.filterPolicy);;
            options.filter_policy = filterPolicy;
        }
        leveldb::Status status = leveldb::DB::Open(options, [_path UTF8String], &db);
        
        readOptions.fill_cache = true;
        writeOptions.sync = false;
        
        if(!status.ok()) {
            NSLog(@"Problem creating LevelDB database: %s", status.ToString().c_str());
        }
        
        self.encoder = ^ NSData *(LevelDBKey *key, id object) {
#ifdef DEBUG
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"No encoder block was set for this database [%@]", name);
                NSLog(@"Using a convenience encoder/decoder pair using NSKeyedArchiver.");
            });
#endif
            return [NSKeyedArchiver archivedDataWithRootObject:object];
        };
        self.decoder = ^ id (LevelDBKey *key, NSData *data) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        };
    }
    
    return self;
}

+ (id) databaseInLibraryWithName:(NSString *)name {
    LevelDBOptions opts = MakeLevelDBOptions();
    return [self databaseInLibraryWithName:name andOptions:opts];
}
+ (id) databaseInLibraryWithName:(NSString *)name
                      andOptions:(LevelDBOptions)opts {
    NSString *path = [getLibraryPath() stringByAppendingPathComponent:name];
    LevelDB *ldb = [[[self alloc] initWithPath:path name:name andOptions:opts] autorelease];
    return ldb;
}

- (void) setSafe:(BOOL)safe {
    writeOptions.sync = safe;
}
- (BOOL) safe {
    return writeOptions.sync;
}
- (void) setUseCache:(BOOL)useCache {
    readOptions.fill_cache = useCache;
}
- (BOOL) useCache {
    return readOptions.fill_cache;
}

#pragma mark - Setters

- (void) setObject:(id)value forKey:(id)key {
    AssertDBExists(db);
    AssertKeyType(key);
    NSParameterAssert(value != nil);
    
    leveldb::Slice k = KeyFromStringOrData(key);
    LevelDBKey lkey = GenericKeyFromSlice(k);

    NSData *data = _encoder(&lkey, value);
    leveldb::Slice v = SliceFromData(data);
    
    leveldb::Status status = db->Put(writeOptions, k, v);
    
    if(!status.ok()) {
        NSLog(@"Problem storing key/value pair in database: %s", status.ToString().c_str());
    }
}
- (void) setValue:(id)value forKey:(NSString *)key {
    [self setObject:value forKey:key];
}
- (void) setObject:(id)value forKeyedSubscript:(id)key {
    [self setObject:value forKey:key];
}
- (void) addEntriesFromDictionary:(NSDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setObject:obj forKey:key];
    }];
}

#pragma mark - Write batches

- (LDBWritebatch *)newWritebatch {
    return [[LDBWritebatch writeBatchFromDB:self] retain];
}

- (void) applyWritebatch:(LDBWritebatch *)writeBatch {
    leveldb::WriteBatch wb = [writeBatch writeBatch];
    leveldb::Status status = db->Write(writeOptions, &wb);
    if(!status.ok()) {
        NSLog(@"Problem applying the write batch in database: %s", status.ToString().c_str());
    }
}

#pragma mark - Getters

- (id) objectForKey:(id)key {
    return [self objectForKey:key withSnapshot:nil];
}
- (id) objectForKey:(id)key
       withSnapshot:(LDBSnapshot *)snapshot {
    
    AssertDBExists(db);
    AssertKeyType(key);
    std::string v_string;
    MaybeAddSnapshotToOptions(readOptions, readOptionsPtr, snapshot);
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = db->Get(*readOptionsPtr, k, &v_string);
    
    if(!status.ok()) {
        if(!status.IsNotFound())
            NSLog(@"Problem retrieving value for key '%@' from database: %s", key, status.ToString().c_str());
        return nil;
    }
    
    LevelDBKey lkey = GenericKeyFromSlice(k);
    return DecodeFromSlice(v_string, &lkey, _decoder);
}
- (id) objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:keys.count];
    [keys enumerateObjectsUsingBlock:^(id objId, NSUInteger idx, BOOL *stop) {
        id object = [self objectForKey:objId];
        if (object == nil) object = marker;
        result[idx] = object;
    }];
    return [NSArray arrayWithArray:result];
}
- (id) valueForKey:(NSString *)key {
    if ([key characterAtIndex:0] == '@') {
        return [super valueForKey:[key stringByReplacingCharactersInRange:(NSRange){0, 1}
                                                               withString:@""]];
    } else
        return [self objectForKey:key];
}
- (id) objectForKeyedSubscript:(id)key {
    return [self objectForKey:key withSnapshot:nil];
}

- (BOOL) objectExistsForKey:(id)key {
    return [self objectExistsForKey:key withSnapshot:nil];
}
- (BOOL) objectExistsForKey:(id)key
               withSnapshot:(LDBSnapshot *)snapshot {
    
    AssertDBExists(db);
    AssertKeyType(key);
    std::string v_string;
    MaybeAddSnapshotToOptions(readOptions, readOptionsPtr, snapshot);
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = db->Get(*readOptionsPtr, k, &v_string);
    
    if (!status.ok()) {
        if (status.IsNotFound())
            return false;
        else {
            NSLog(@"Problem retrieving value for key '%@' from database: %s", key, status.ToString().c_str());
            return NULL;
        }
    } else
        return true;
}

#pragma mark - Removers

- (void) removeObjectForKey:(id)key {
    AssertDBExists(db);
    AssertKeyType(key);
    
    leveldb::Slice k = KeyFromStringOrData(key);
    leveldb::Status status = db->Delete(writeOptions, k);
    
    if(!status.ok()) {
        NSLog(@"Problem deleting key/value pair in database: %s", status.ToString().c_str());
    }
}
- (void) removeObjectsForKeys:(NSArray *)keyArray {
    [keyArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeObjectForKey:obj];
    }];
}

- (void) removeAllObjects {
    [self removeAllObjectsWithPrefix:nil];
}
- (void) removeAllObjectsWithPrefix:(id)prefix {
    AssertDBExists(db);
    
    leveldb::Iterator * iter = db->NewIterator(readOptions);
    leveldb::Slice lkey;
    
    const void *prefixPtr;
    size_t prefixLen;
    prefix = EnsureNSData(prefix);
    if (prefix) {
        prefixPtr = [(NSData *)prefix bytes];
        prefixLen = (size_t)[(NSData *)prefix length];
    }

    for (SeekToFirstOrKey(iter, (id)prefix, NO)
         ; iter->Valid()
         ; MoveCursor(iter, NO)) {
        
        lkey = iter->key();
        if (prefix && memcmp(lkey.data(), prefixPtr, MIN(prefixLen, lkey.size())) != 0)
            break;
        
        db->Delete(writeOptions, lkey);
    }
    delete iter;
}

#pragma mark - Selection

- (NSArray *)allKeys {
    NSMutableArray *keys = [[[NSMutableArray alloc] init] autorelease];
    [self enumerateKeysUsingBlock:^(LevelDBKey *key, BOOL *stop) {
        [keys addObject:NSDataFromLevelDBKey(key)];
    }];
    return [NSArray arrayWithArray:keys];
}
- (NSArray *)keysByFilteringWithPredicate:(NSPredicate *)predicate {
    NSMutableArray *keys = [[[NSMutableArray alloc] init] autorelease];
    [self enumerateKeysAndObjectsBackward:NO lazily:NO
                            startingAtKey:nil
                      filteredByPredicate:predicate
                                andPrefix:nil
                             withSnapshot:nil
                               usingBlock:^(LevelDBKey *key, id obj, BOOL *stop) {
                                   [keys addObject:NSDataFromLevelDBKey(key)];
                               }];
    return [NSArray arrayWithArray:keys];
}

- (NSDictionary *)dictionaryByFilteringWithPredicate:(NSPredicate *)predicate {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [self enumerateKeysAndObjectsBackward:NO lazily:NO
                            startingAtKey:nil
                      filteredByPredicate:predicate
                                andPrefix:nil
                             withSnapshot:nil
                               usingBlock:^(LevelDBKey *key, id obj, BOOL *stop) {
                                   [results setObject:obj forKey:NSDataFromLevelDBKey(key)];
                               }];
    
    return [NSDictionary dictionaryWithDictionary:results];
}

- (LDBSnapshot *) newSnapshot {
    return [[LDBSnapshot snapshotFromDB:self] retain];
}

#pragma mark - Enumeration

- (void) _startIterator:(leveldb::Iterator*)iter
               backward:(BOOL)backward
                 prefix:(id)prefix
                  start:(id)key {
    
    const void *prefixPtr;
    size_t prefixLen;
    leveldb::Slice lkey, startingKey;
    
    prefix = EnsureNSData(prefix);
    if (prefix) {
        prefixPtr = [(NSData *)prefix bytes];
        prefixLen = (size_t)[(NSData *)prefix length];
        startingKey = leveldb::Slice((char *)prefixPtr, prefixLen);
        
        if (key) {
            leveldb::Slice skey = KeyFromStringOrData(key);
            if (skey.size() > prefixLen && memcmp(skey.data(), prefixPtr, prefixLen) == 0) {
                startingKey = skey;
            }
        }
        
        /*
         * If a prefix is provided and the iteration is backwards
         * we need to start on the next key (maybe discarding the first iteration)
         */
        if (backward) {
            signed long long i = startingKey.size() - 1;
            void * startingKeyPtr = malloc(startingKey.size());
            unsigned char *keyChar;
            memcpy(startingKeyPtr, startingKey.data(), startingKey.size());
            while (1) {
                if (i < 0) {
                    iter->SeekToLast();
                    break;
                }
                keyChar = (unsigned char *)startingKeyPtr + i;
                if (*keyChar < 255) {
                    *keyChar = *keyChar + 1;
                    iter->Seek(leveldb::Slice((char *)startingKeyPtr, prefixLen));
                    if (!iter->Valid()) {
                        iter->SeekToLast();
                    }
                    break;
                }
                i--;
            };
            free(startingKeyPtr);
            if (!iter->Valid())
                return;
            
            lkey = iter->key();
            if (prefix && memcmp(lkey.data(), prefixPtr, prefixLen) != 0) {
                iter->Prev();
            }
        } else {
            // Otherwise, we start at the provided prefix
            iter->Seek(startingKey);
        }
    } else if (key) {
        iter->Seek(KeyFromStringOrData(key));
    } else if (backward) {
        iter->SeekToLast();
    } else {
        iter->SeekToFirst();
    }
}

- (void) enumerateKeysUsingBlock:(LevelDBKeyBlock)block {
    
    [self enumerateKeysBackward:FALSE
                  startingAtKey:nil
            filteredByPredicate:nil
                      andPrefix:nil
                   withSnapshot:nil
                     usingBlock:block];
}

- (void)enumerateKeysBackward:(BOOL)backward
                startingAtKey:(id)key
          filteredByPredicate:(NSPredicate *)predicate
                    andPrefix:(id)prefix
                   usingBlock:(LevelDBKeyBlock)block {
    
    [self enumerateKeysBackward:backward
                  startingAtKey:key
            filteredByPredicate:predicate
                      andPrefix:prefix
                   withSnapshot:nil
                     usingBlock:block];
}

- (void) enumerateKeysBackward:(BOOL)backward
                 startingAtKey:(id)key
           filteredByPredicate:(NSPredicate *)predicate
                     andPrefix:(id)prefix
                  withSnapshot:(LDBSnapshot *)snapshot
                    usingBlock:(LevelDBKeyBlock)block {
    
    AssertDBExists(db);
    MaybeAddSnapshotToOptions(readOptions, readOptionsPtr, snapshot);
    leveldb::Iterator* iter = db->NewIterator(*readOptionsPtr);
    leveldb::Slice lkey;
    BOOL stop = false;
    
    NSData *prefixData = EnsureNSData(prefix);
    
    LevelDBKeyValueBlock iterate = (predicate != nil)
        ? ^(LevelDBKey *lk, id value, BOOL *stop) {
            if ([predicate evaluateWithObject:value])
                block(lk, stop);
          }
        : ^(LevelDBKey *lk, id value, BOOL *stop) {
            block(lk, stop);
          };
    
    for ([self _startIterator:iter backward:backward prefix:prefix start:key]
         ; iter->Valid()
         ; MoveCursor(iter, backward)) {
        
        lkey = iter->key();
        if (prefix && memcmp(lkey.data(), [prefixData bytes], MIN((size_t)[prefixData length], lkey.size())) != 0)
            break;
        
        LevelDBKey lk = GenericKeyFromSlice(lkey);
        id v = (predicate == nil) ? nil : DecodeFromSlice(iter->value(), &lk, _decoder);
        iterate(&lk, v, &stop);
        if (stop) break;
    }
    
    delete iter;
}

- (void) enumerateKeysAndObjectsUsingBlock:(LevelDBKeyValueBlock)block {
    [self enumerateKeysAndObjectsBackward:FALSE
                                   lazily:FALSE
                            startingAtKey:nil
                      filteredByPredicate:nil
                                andPrefix:nil
                             withSnapshot:nil
                               usingBlock:block];
}

- (void)enumerateKeysAndObjectsBackward:(BOOL)backward
                                 lazily:(BOOL)lazily
                          startingAtKey:(id)key
                    filteredByPredicate:(NSPredicate *)predicate
                              andPrefix:(id)prefix
                             usingBlock:(id)block {
    
    [self enumerateKeysAndObjectsBackward:backward
                                   lazily:lazily
                            startingAtKey:key
                      filteredByPredicate:predicate
                                andPrefix:prefix
                             withSnapshot:nil
                               usingBlock:block];
}

- (void) enumerateKeysAndObjectsBackward:(BOOL)backward
                                  lazily:(BOOL)lazily
                           startingAtKey:(id)key
                     filteredByPredicate:(NSPredicate *)predicate
                               andPrefix:(id)prefix
                            withSnapshot:(LDBSnapshot *)snapshot
                              usingBlock:(id)block{
    
    AssertDBExists(db);
    MaybeAddSnapshotToOptions(readOptions, readOptionsPtr, snapshot);
    leveldb::Iterator* iter = db->NewIterator(*readOptionsPtr);
    leveldb::Slice lkey;
    BOOL stop = false;
    
    LevelDBLazyKeyValueBlock iterate = (predicate != nil)
    
        // If there is a predicate:
        ? ^ (LevelDBKey *lk, LevelDBValueGetterBlock valueGetter, BOOL *stop) {
            // We need to get the value, whether the `lazily` flag was set or not
            id value = valueGetter();
            
            // If the predicate yields positive, we call the block
            if ([predicate evaluateWithObject:value]) {
                if (lazily)
                    ((LevelDBLazyKeyValueBlock)block)(lk, valueGetter, stop);
                else
                    ((LevelDBKeyValueBlock)block)(lk, value, stop);
            }
        }
    
        // Otherwise, we call the block
        : ^ (LevelDBKey *lk, LevelDBValueGetterBlock valueGetter, BOOL *stop) {
            if (lazily)
                ((LevelDBLazyKeyValueBlock)block)(lk, valueGetter, stop);
            else
                ((LevelDBKeyValueBlock)block)(lk, valueGetter(), stop);
        };
    
    NSData *prefixData = EnsureNSData(prefix);
    
    LevelDBValueGetterBlock getter;
    for ([self _startIterator:iter backward:backward prefix:prefix start:key]
         ; iter->Valid()
         ; MoveCursor(iter, backward)) {
        
        lkey = iter->key();
        // If there is prefix provided, and the prefix and key don't match, we break out of iteration
        if (prefix && memcmp(lkey.data(), [prefixData bytes], MIN((size_t)[prefixData length], lkey.size())) != 0)
            break;
        
        __block LevelDBKey lk = GenericKeyFromSlice(lkey);
        __block id v = nil;
        
        getter = ^ id {
            if (v) return v;
            v = DecodeFromSlice(iter->value(), &lk, _decoder);
            return v;
        };
        
        iterate(&lk, getter, &stop);
        if (stop) break;
    }
    
    delete iter;
}

#pragma mark - Bookkeeping

- (void) deleteDatabaseFromDisk {
    [self close];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:_path error:&error];
}

- (void) close {
    @synchronized(self) {
        if (db) {
            delete db;
            
            if (cache)
                delete cache;
            
            if (filterPolicy)
                delete filterPolicy;
            
            db = NULL;
        }
    }
}
- (BOOL) closed {
    return db == NULL;
}
- (void) dealloc {
    [self close];
    [super dealloc];
}

@end
