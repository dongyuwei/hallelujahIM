//
//  LDBSnapshot.mm
//
//  Copyright 2013 Storm Labs.
//  See LICENCE for details.
//

#import "LDBSnapshot.h"
#import <leveldb/db.h>

@interface LevelDB ()

- (leveldb::DB *)db;

- (void) enumerateKeysBackward:(BOOL)backward
                 startingAtKey:(id)key
           filteredByPredicate:(NSPredicate *)predicate
                     andPrefix:(id)prefix
                  withSnapshot:(LDBSnapshot *)snapshot
                    usingBlock:(LevelDBKeyBlock)block;

- (void) enumerateKeysAndObjectsBackward:(BOOL)backward
                                  lazily:(BOOL)lazily
                           startingAtKey:(id)key
                     filteredByPredicate:(NSPredicate *)predicate
                               andPrefix:(id)prefix
                            withSnapshot:(LDBSnapshot *)snapshot
                              usingBlock:(id)block;

- (id) objectForKey:(id)key
       withSnapshot:(LDBSnapshot *)snapshot;

- (BOOL) objectExistsForKey:(id)key
               withSnapshot:(LDBSnapshot *)snapshot;

@end

@interface LDBSnapshot () {
    const leveldb::Snapshot * _snapshot;
}

@property (readonly, getter = getSnapshot) const leveldb::Snapshot * snapshot;
- (const leveldb::Snapshot *) getSnapshot;

@end

@implementation LDBSnapshot 

+ (LDBSnapshot *) snapshotFromDB:(LevelDB *)database {
    LDBSnapshot *snapshot = [[[LDBSnapshot alloc] init] autorelease];
    snapshot->_snapshot = [database db]->GetSnapshot();
    snapshot->_db = database;
    return snapshot;
}

- (const leveldb::Snapshot *) getSnapshot {
    return _snapshot;
}

- (id) objectForKey:(id)key {
    return [_db objectForKey:key withSnapshot:self];
}
- (id)objectForKeyedSubscript:(id)key {
    return [_db objectForKey:key withSnapshot:self];
}
- (BOOL) objectExistsForKey:(id)key {
    return [_db objectExistsForKey:key withSnapshot:self];
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
        return [_db objectForKey:key withSnapshot:self];
}

- (NSArray *)allKeys {
    NSMutableArray *keys = [[[NSMutableArray alloc] init] autorelease];
    [self enumerateKeysUsingBlock:^(LevelDBKey *key, BOOL *stop) {
        [keys addObject:NSDataFromLevelDBKey(key)];
    }];
    return [NSArray arrayWithArray:keys];
}
- (NSArray *)keysByFilteringWithPredicate:(NSPredicate *)predicate {
    NSMutableArray *keys = [[[NSMutableArray alloc] init] autorelease];
    [self enumerateKeysBackward:NO
                  startingAtKey:nil
            filteredByPredicate:predicate
                      andPrefix:nil
                     usingBlock:^(LevelDBKey *key, BOOL *stop) {
                         [keys addObject:NSDataFromLevelDBKey(key)];
                     }];
    
    return [NSArray arrayWithArray:keys];
}

- (NSDictionary *)dictionaryByFilteringWithPredicate:(NSPredicate *)predicate {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    [self enumerateKeysAndObjectsBackward:NO
                                   lazily:NO
                            startingAtKey:nil
                      filteredByPredicate:predicate
                                andPrefix:nil
                               usingBlock:^(LevelDBKey *key, id obj, BOOL *stop) {
                                   [results setObject:obj forKey:NSDataFromLevelDBKey(key)];
                               }];
    
    return [NSDictionary dictionaryWithDictionary:results];
}

- (void)enumerateKeysUsingBlock:(LevelDBKeyBlock)block {
    [_db enumerateKeysBackward:NO
                 startingAtKey:nil
           filteredByPredicate:nil
                     andPrefix:nil
                  withSnapshot:self
                    usingBlock:block];
}
- (void)enumerateKeysBackward:(BOOL)backward
                startingAtKey:(id)key
          filteredByPredicate:(NSPredicate *)predicate
                    andPrefix:(id)prefix
                   usingBlock:(LevelDBKeyBlock)block {
    [_db enumerateKeysBackward:backward
                 startingAtKey:key
           filteredByPredicate:predicate
                     andPrefix:prefix
                  withSnapshot:self
                    usingBlock:block];
}

- (void)enumerateKeysAndObjectsUsingBlock:(LevelDBKeyValueBlock)block {
    [_db enumerateKeysAndObjectsBackward:NO
                                  lazily:NO
                           startingAtKey:nil
                     filteredByPredicate:nil
                               andPrefix:nil
                            withSnapshot:self
                              usingBlock:block];
}
- (void)enumerateKeysAndObjectsBackward:(BOOL)backward
                                 lazily:(BOOL)lazily
                          startingAtKey:(id)key
                    filteredByPredicate:(NSPredicate *)predicate
                              andPrefix:(id)prefix
                             usingBlock:(id)block {
    [_db enumerateKeysAndObjectsBackward:backward
                                  lazily:lazily
                           startingAtKey:key
                     filteredByPredicate:predicate
                               andPrefix:prefix
                            withSnapshot:self
                              usingBlock:block];
}

- (void) close {
    if (_snapshot) {
        [_db db]->ReleaseSnapshot(_snapshot);
        _snapshot = nil;
    }
}
- (void) dealloc {
    [self close];
    [super dealloc];
}

@end