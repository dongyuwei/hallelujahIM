//
//  FBTable.h
//  flatbuf-objc
//
//  Created by SC on 16/5/18.
//  Copyright © 2016年 SC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConstants.h"
#import "FBMutableData.h"
#import "FBMutableArray.h"

@interface FBTable : NSObject{
    
@protected
    int            bb_pos;
    int            origin_size;
    FBMutableData *bb;
}

+ (instancetype)getRootAs:(NSData*)data;

+ (BOOL)verifier:(NSData*)data;

- (instancetype)init:(int) _i bb:(FBMutableData*) _bb ;

- (FBMutableData *)getByteBuffer;

- (NSData *)getData;

- (int)fb_offset:(int)vtable_offset;

- (void)fb_set_offset:(int)vtable_offset value:(int)value;

- (int)fb_indirect:(int) offset;

- (void)fb_set_indirect:(int) offset value:(int32_t)value;

- (NSString *) fb_string:(int)offset;

- (void) fb_add_string:(NSString *)string offset:(int)offset;

- (void) fb_add_data:(NSData *)data offset:(int)offset;

- (void) fb_set_data:(NSData *)data offset:(int)offset;

- (int) fb_vector_len:(int)offset;

- (int) fb_vector:(int)offset;

- (FBMutableData *) fb_vector_as_data:(int)vector_offset size:(int)elem_size;

- (FBTable*) fb_union:(FBTable*) t offset:(int) offset;


- (BOOL) fb_getBool:(int)offset origin:(BOOL)origin;

- (int8_t) fb_getInt8:(int)offset origin:(int8_t)origin;

- (uint8_t) fb_getUint8:(int)offset origin:(uint8_t)origin;

- (int16_t) fb_getInt16:(int)offset origin:(int16_t)origin;

- (uint16_t) fb_getUint16:(int)offset origin:(uint16_t)origin;

- (int32_t) fb_getInt32:(int)offset origin:(int32_t)origin;

- (uint32_t) fb_getUint32:(int)offset origin:(uint32_t)origin;

- (int64_t) fb_getInt64:(int)offset origin:(int64_t)origin;

- (uint64_t) fb_getUint64:(int)offset origin:(uint64_t)origin;

- (float) fb_getFloat:(int)offset origin:(float)origin;

- (double) fb_getDouble:(int)offset origin:(double)origin;

- (id ) fb_getStruct:(int)offset origin:(id)origin className:(Class)itemClass;

- (NSString *) fb_getString:(int)offset origin:(NSString *)origin;

- (id) fb_getTable:(int)offset origin:(id)origin className:(Class)itemClass;

- (FBMutableArray<NSNumber *> *) fb_getNumbers:(int)offset origin:(FBMutableArray<NSNumber *> *)origin type:(FBNumberType)type;

- (FBMutableArray *) fb_getStructs:(int)offset origin:(id)origin className:(Class)itemClass byteSize:(int)byteSize;

- (FBMutableArray<NSString *> *) fb_getStrings:(int)offset origin:(FBMutableArray<NSString *> *)origin;

- (FBMutableArray *) fb_getTables:(int)offset origin:(id)origin className:(Class)itemClass;


// build method
- (void) fb_setBool:(BOOL)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setInt8:(int8_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setUint8:(uint8_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setInt16:(int16_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setUint16:(uint16_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setInt32:(int32_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setUint32:(uint32_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setInt64:(int64_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setUint64:(uint64_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setFloat:(float)value voffset:(int)voffset offset:(int)offset;

- (void) fb_setDouble:(double)value voffset:(int)voffset offset:(int)offset;


- (void) fb_addBool:(BOOL)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addInt8:(int8_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addUint8:(uint8_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addInt16:(int16_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addUint16:(uint16_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addInt32:(int32_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addUint32:(uint32_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addInt64:(int64_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addUint64:(uint64_t)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addFloat:(float)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addDouble:(double)value voffset:(int)voffset offset:(int)offset;

- (void) fb_addString:(NSString *)string voffset:(int)voffset offset:(int)offset;

- (void) fb_addStruct:(FBTable *)table voffset:(int)voffset offset:(int)offset;

- (void) fb_addTable:(FBTable *)table voffset:(int)voffset offset:(int)offset;

- (void) fb_addNumbers:(FBMutableArray*)numbers voffset:(int)voffset offset:(int)offset type:(FBNumberType)type;

- (void) fb_addStructs:(FBMutableArray*)structs voffset:(int)voffset offset:(int)offset;

- (void) fb_addStrings:(FBMutableArray*)strings voffset:(int)voffset offset:(int)offset;

- (void) fb_addTables:(FBMutableArray*)tables voffset:(int)voffset offset:(int)offset;

+ (BOOL) fb_has_identifier:(FBMutableData *)bb ident:(NSString *)ident;
@end
