//
//  FBTable .m
//  flatbuf-objc
//
//  Created by SC on 16/5/18.
//  Copyright © 2016年 SC. All rights reserved.
//

#import "FBTable.h"
#import <objc/runtime.h>

@implementation FBTable 

+ (instancetype)getRootAs:(NSData*)data {

    FBMutableData *_bb = [[FBMutableData alloc]initWithData:data];
    
    return [[[self class] alloc] init:[_bb getInt32 :0] bb:_bb];
}

+ (BOOL)verifier:(NSData*)data{
    
    BOOL isVerifier = YES;
    
    FBMutableData *bb = [[FBMutableData alloc] initWithData:data];
    int soffset = [bb getInt32:0];
    if (soffset >= bb.length) {
        return NO;
    }
    
    int voffset = soffset - [bb getInt32:soffset];
    if (voffset+4 >= soffset || voffset < 0) {
        return NO;
    }
    
    int vMaxOffset = [bb getInt16:voffset];
    if (vMaxOffset > (soffset-voffset) || vMaxOffset <= 0) {
        return NO;
    }
    
    int payloadSize = [bb getInt16:voffset+2];
    if (payloadSize > bb.length-soffset || payloadSize < 0) {
        return NO;
    }
    
    for (int i = 0; i < (vMaxOffset-4)/2; i++) {
        int vItem = [bb getInt16:voffset+4+i*2];
        if (vItem >= bb.length || vItem < 0) {
            return NO;
        }
    }
    
    return isVerifier;
    
}

- (instancetype)init:(int) _i bb:(FBMutableData*) _bb {
    
    if (self = [super init]) {
        
        bb_pos = _i;
        
        bb = _bb;
    }
    
    return self;
}


- (FBMutableData *)getByteBuffer{
    
    return bb;
    
}

- (NSData *) getData{
    u_int   count    = 0;
    Method *methods  = class_copyMethodList([self class], &count);
    
    [bb cutOffWithRange:NSMakeRange(0, origin_size)];
   
    for (int i = 0; i < count ; i++)
    {
        SEL name = method_getName(methods[i]);
        NSString *strName = [NSString  stringWithCString:sel_getName(name) encoding:NSUTF8StringEncoding];
        if ([strName hasPrefix:@"add_"]) {
            NSThread *thread = [NSThread currentThread];
            [self performSelector:name onThread:thread withObject:nil waitUntilDone:YES];
        }
    }
    
    return [bb data];
    
}

- (int)fb_offset:(int)vtable_offset {
    
    int vtable = bb_pos - [bb getInt32 :bb_pos];
    
    return vtable_offset < [bb getInt16:vtable] ? [bb getInt16:vtable + vtable_offset] : 0;
    
}

- (void)fb_set_offset:(int)vtable_offset value:(int)value {
    
    int vtable = bb_pos - [bb getInt32 :bb_pos];
    
    if (vtable_offset <= [bb getInt16:vtable]){
      
        [bb setInt16:(int16_t)value offset:vtable + vtable_offset];
        
    }
    
}

- (int)fb_indirect:(int) offset {
    
    return offset + [bb getInt32 :offset];
    
}

- (void)fb_set_indirect:(int) offset value:(int32_t)value{
    
    [bb setInt32:value offset:offset];
    
}

- (NSString *) fb_string:(int)offset {
    
    offset += [bb getInt32 :offset];
    
    int length = [bb getInt32 :offset];
    
    return [bb stringWithOffset:offset + SIZEOF_INT length:length];
}

- (void) fb_add_string:(NSString *)string offset:(int)offset {
    
    [bb setInt32:(int32_t)(bb.length-offset) offset:offset];
    
    [bb appenddingString:string];
    
    return ;
}

- (void) fb_add_data:(NSData *)data offset:(int)offset {
    
    [bb setInt32:(int32_t)(bb.length-offset) offset:offset];
    
    [bb appenddingData:data];
    
    return ;
}

- (void) fb_add_data_table:(NSData *)data offset:(int)offset {
    
    [bb setInt32:(int32_t)(bb.length-offset)+16 offset:offset];
    
    [bb appenddingData:data];
    
    return ;
}

- (void) fb_set_data:(NSData *)data offset:(int)offset {
    
    [bb replaceBytesInRange:NSMakeRange(offset, data.length) withBytes:data.bytes];
    
    return ;
}

- (int) fb_vector_len:(int)offset {
    
    offset += bb_pos;
    
    offset += [bb getInt32 :offset];
    
    return [bb getInt32 :offset];
}

- (int) fb_vector:(int)offset {
    
    offset += bb_pos;
    
    return offset + [bb getInt32 :offset] + SIZEOF_INT;
    
}

- (FBMutableData *) fb_vector_as_data:(int)vector_offset size:(int)elem_size {
    
    int o = [self fb_offset:vector_offset];
    
    if (o == 0) return [FBMutableData dataWithCapacity:0];
    
    int vectorstart = [self fb_vector:o];
    
    return [FBMutableData dataWithData:[bb subdataWithRange:NSMakeRange(vectorstart, [self fb_vector_len:0] * elem_size)]];
    
}

- (FBTable *) fb_union:(FBTable *) t offset:(int) offset {
    
    offset += bb_pos;
    
    t->bb_pos = offset + [bb getInt32:offset];
    
    t->bb = bb;
    
    return t;
}

- (BOOL) fb_getBool:(int)offset origin:(BOOL)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getBool:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (int8_t) fb_getInt8:(int)offset origin:(int8_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getInt8:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (uint8_t) fb_getUint8:(int)offset origin:(uint8_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getUint8:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (int16_t) fb_getInt16:(int)offset origin:(int16_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getInt16:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (uint16_t) fb_getUint16:(int)offset origin:(uint16_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getUint16:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (int32_t) fb_getInt32:(int)offset origin:(int32_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getInt32:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (uint32_t) fb_getUint32:(int)offset origin:(uint32_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getUint32:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (int64_t) fb_getInt64:(int)offset origin:(int64_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getInt64:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (uint64_t) fb_getUint64:(int)offset origin:(uint64_t)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getUint64:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (float) fb_getFloat:(int)offset origin:(float)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [bb getFloat:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (double) fb_getDouble:(int)offset origin:(double)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
        
            origin = [bb getDouble:o+bb_pos];
        
        }
    }
    
    return origin;
}

- (id ) fb_getStruct:(int)offset origin:(id)origin className:(Class)itemClass{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
        
            origin = [[itemClass alloc] init:o+bb_pos bb:bb];
        
        }
    }
    
    return origin;
}

- (NSString *) fb_getString:(int)offset origin:(NSString *)origin{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
            
            origin = [self fb_string:o+bb_pos];
            
        }
    }
    
    return origin;
}

- (id) fb_getTable:(int)offset origin:(id)origin className:(Class)itemClass{
    
    if (!origin) {
        
        int o = [self fb_offset:offset];
        
        if (o != 0) {
        
            origin = [[itemClass alloc] init:[self fb_indirect:o + bb_pos] bb:bb];
        
        }
    }
    
    return origin;
}

- (FBMutableArray<NSNumber *> *) fb_getNumbers:(int)offset origin:(FBMutableArray<NSNumber *> *)origin type:(FBNumberType)type{
    
    if (!origin) {
        
        origin = [FBMutableArray new];
        FBMutableArray *temp = origin;
        int tempOffset = [self fb_offset:offset];
        int length = 0;
        
        if (tempOffset != 0) {
            
            length = [self fb_vector_len:tempOffset];
            
        }
        
        int o = [self fb_offset:offset];
        
        if (length > 0 && o > 0) {
            
            id item = nil;
            int numberSize = [self fb_number_length:type];
            
            for (int i = 0 ; i < length ; i++) {
                
                switch (type) {
                    case FBNumberBool:

                        item = [NSNumber numberWithBool:[bb getBool:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberChar:
                        
                        item = [NSNumber numberWithChar:[bb getInt8:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberUChar:
                        
                        item = [NSNumber numberWithUnsignedChar:[bb getUint8:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberInt8:
                        
                        item = [NSNumber numberWithChar:[bb getInt8:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberUint8:
                        
                        item = [NSNumber numberWithUnsignedChar:[bb getUint8:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberInt16:
                        
                        item = [NSNumber numberWithShort:[bb getInt16:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberUint16:
                        
                        item = [NSNumber numberWithUnsignedShort:[bb getUint16:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberInt32:
                        
                        item = [NSNumber numberWithInt:[bb getInt32:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberUint32:
                        
                        item = [NSNumber numberWithUnsignedInt:[bb getUint32:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberInt64:
                        
                        item = [NSNumber numberWithLongLong:[bb getInt64:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberUint64:
                        
                        item = [NSNumber numberWithUnsignedLongLong:[bb getUint64:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberFloat:
                        
                        item = [NSNumber numberWithFloat:[bb getFloat:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                    case FBNumberDouble:
                        
                        item = [NSNumber numberWithDouble:[bb getDouble:[self fb_vector:o] + i * numberSize]];
                        !item ? nil :[temp addObject:item];
                        
                        break;
                        
                    default:
                        break;
                }
                
            }
        }
    }
    
    return origin;
}


- (FBMutableArray *) fb_getStructs:(int)offset origin:(id)origin className:(Class)itemClass byteSize:(int)byteSize {
    
    if (!origin) {
        
        origin = [FBMutableArray new];
        FBMutableArray *temp = origin;
        int tempOffset = [self fb_offset:offset];
        int length = 0;
        
        if (tempOffset != 0) {
            
            length = [self fb_vector_len:tempOffset];
            
        }
        
        int o = [self fb_offset:offset];
        
        if (length > 0 && o > 0) {
            
            id item = nil;
            
            for (int i = 0 ; i < length ; i++) {
                
                item = [[itemClass alloc] init:[self fb_vector:o] + i * byteSize bb:bb];
                !item ? nil : [temp addObject:item];
                
            }
        }
    }
    
    return origin;
}

- (FBMutableArray<NSString *> *) fb_getStrings:(int)offset origin:(FBMutableArray<NSString *> *)origin {
    
    if (!origin) {
    
        origin = [FBMutableArray new];
        FBMutableArray *temp = origin;
        int tempOffset = [self fb_offset:offset];
        int length = 0;
        
        if (tempOffset != 0) {
        
            length = [self fb_vector_len:tempOffset];
        
        }
        
        int o = [self fb_offset:offset];
        
        if (length > 0 && o > 0) {
        
            id item = nil;
            
            for (int i = 0 ; i < length ; i++) {
            
                item = [self fb_string:[self fb_vector:o] + i * 4];
                !item ? nil : [temp addObject:item];
            
            }
        }
    }
    
    return origin;
}

- (FBMutableArray *) fb_getTables:(int)offset origin:(id)origin className:(Class)itemClass {
    
    if (!origin) {
        
        origin = [FBMutableArray new];
        FBMutableArray *temp = origin;
        int tempOffset = [self fb_offset:offset];
        int length = 0;
        
        if (tempOffset != 0) {
            length = [self fb_vector_len:tempOffset];
        }
        
        int o = [self fb_offset:offset];
        
        if (length > 0 && o > 0) {
       
            id item = nil;
            
            for (int i = 0 ; i < length ; i++) {
            
                item = [[itemClass alloc] init:[self fb_indirect:[self fb_vector:o] + i * 4] bb:bb];
                !item ? nil : [temp addObject:item];
            
            }
        }
    }
    
    return origin;
}

- (int)fb_number_length:(FBNumberType)type{
    
    int length = 0;
    
    switch (type) {
        case FBNumberBool:
            length = 1;
            break;
        case FBNumberChar:
            length = 1;
            break;
        case FBNumberUChar:
            length = 1;
            break;
        case FBNumberInt8:
            length = 1;
            break;
        case FBNumberUint8:
            length = 1;
            break;
        case FBNumberInt16:
            length = 2;
            break;
        case FBNumberUint16:
            length = 2;
            break;
        case FBNumberInt32:
            length = 4;
            break;
        case FBNumberUint32:
            length = 4;
            break;
        case FBNumberInt64:
            length = 8;
            break;
        case FBNumberUint64:
            length = 8;
            break;
        case FBNumberFloat:
            length = 4;
            break;
        case FBNumberDouble:
            length = 8;
            break;
            
        default:
            break;
    }
    
    return length;
}

- (void) fb_setBool:(BOOL)value voffset:(int)voffset offset:(int)offset{

    [bb setBool:value offset:voffset+bb_pos];

    return ;
}

- (void) fb_setInt8:(int8_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setInt8:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setUint8:(uint8_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setUint8:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setInt16:(int16_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setInt16:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setUint16:(uint16_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setUint16:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setInt32:(int32_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setInt32:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setUint32:(uint32_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setUint32:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setInt64:(int64_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setInt64:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setUint64:(uint64_t)value voffset:(int)voffset offset:(int)offset{
    
    [bb setUint64:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setFloat:(float)value voffset:(int)voffset offset:(int)offset{
    
    [bb setFloat:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_setDouble:(double)value voffset:(int)voffset offset:(int)offset{
    
    [bb setDouble:value offset:voffset+bb_pos];
    
    return ;
}

- (void) fb_addBool:(BOOL)value voffset:(int)voffset offset:(int)offset{

    [self fb_set_offset:voffset value:offset];
    [bb setBool:value offset:[self fb_offset:voffset]+bb_pos];

    return ;
}

- (void) fb_addInt8:(int8_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setInt8:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addUint8:(uint8_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setUint8:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}


- (void) fb_addInt16:(int16_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setInt16:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addUint16:(uint16_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setUint16:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addInt32:(int32_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setInt32:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addUint32:(uint32_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setUint32:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addInt64:(int64_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setInt64:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addUint64:(uint64_t)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setUint64:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addFloat:(float)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setFloat:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addDouble:(double)value voffset:(int)voffset offset:(int)offset{
    
    [self fb_set_offset:voffset value:offset];
    [bb setDouble:value offset:[self fb_offset:voffset]+bb_pos];
    
    return ;
}

- (void) fb_addString:(NSString *)string voffset:(int)voffset offset:(int)offset{
    if (string) {
        [self fb_set_offset:voffset value:offset];
        [self fb_add_string:string offset:[self fb_offset:voffset]+bb_pos];
    }
    return ;
}

- (void) fb_addStruct:(FBTable *)table voffset:(int)voffset offset:(int)offset {
    
    [self fb_set_offset:voffset value:offset];

    [self fb_set_data:[table getData] offset:[self fb_offset:voffset]+bb_pos];

    return ;
}

- (void) fb_addTable:(FBTable *)table voffset:(int)voffset offset:(int)offset {
    
    [self fb_set_offset:voffset value:offset];

//    [self fb_add_data_table:[table getData] offset:[self fb_offset:voffset]+bb_pos];
    int temOffset = [self fb_offset:voffset]+bb_pos;
    [bb setInt32:(int32_t)(bb.length-temOffset)+table->bb_pos offset:temOffset];
    
    [bb appenddingData:[table getData]];

    return ;
}

- (void) fb_addNumbers:(FBMutableArray*)numbers voffset:(int)voffset offset:(int)offset type:(FBNumberType)type {
    if (numbers) {
        FBMutableArray *temp = numbers;
        int length = (int)temp.count;
        if (length > 0) {
            NSNumber *item = nil;
            [self fb_set_offset:voffset value:offset];
            FBMutableData *data = [[FBMutableData alloc]initWithLength:4+length*[self fb_number_length:type]];
            [data setInt32:length offset:0];
            for (int i = 0 ; i < length ; i++) {
                item = (NSNumber*)temp[i];
                switch (type) {
                    case FBNumberBool:
                        [data setBool:item.boolValue offset:1*i+4];
                        break;
                    case FBNumberChar:
                        [data setInt8:item.charValue offset:1*i+4];
                        break;
                    case FBNumberUChar:
                        [data setUint8:item.unsignedCharValue offset:1*i+4];
                        break;
                    case FBNumberInt8:
                        [data setInt8:item.charValue offset:1*i+4];
                        break;
                    case FBNumberUint8:
                        [data setUint8:item.charValue offset:1*i+4];
                        break;
                    case FBNumberInt16:
                        [data setInt16:item.shortValue offset:2*i+4];
                        break;
                    case FBNumberUint16:
                        [data setUint16:item.unsignedShortValue offset:2*i+4];
                        break;
                    case FBNumberInt32:
                        [data setInt32:item.intValue offset:4*i+4];
                        break;
                    case FBNumberUint32:
                        [data setUint32:item.unsignedIntValue offset:4*i+4];
                        break;
                    case FBNumberInt64:
                        [data setInt64:item.longLongValue offset:8*i+4];
                        break;
                    case FBNumberUint64:
                        [data setInt64:item.unsignedLongLongValue offset:8*i+4];
                        break;
                    case FBNumberFloat:
                        [data setFloat:item.floatValue offset:4*i+4];
                        break;
                    case FBNumberDouble:
                        [data setDouble:item.doubleValue offset:8*i+4];
                        break;
                        
                    default:
                        break;
                }
            }
            [self fb_add_data:[data data] offset:[self fb_offset:voffset]+bb_pos];
        }
    }
    return ;
}

- (void) fb_addStructs:(FBMutableArray*)structs voffset:(int)voffset offset:(int)offset {
    if (structs) {
        FBMutableArray *temp = structs;
        int length = (int)temp.count;
        if (length > 0) {
            FBTable *item = nil;
            [self fb_set_offset:voffset value:offset];
            FBMutableData *data = [[FBMutableData alloc]initWithLength:4];
            [data setInt32:length offset:0];
            for (int i = 0 ; i < length ; i++) {
                item = (FBTable*)temp[i];
                [data appendData:[item getData]];
            }
            
            [self fb_add_data:[data data] offset:[self fb_offset:voffset]+bb_pos];
        }
    }
    return ;
}

- (void) fb_addStrings:(FBMutableArray*)strings voffset:(int)voffset offset:(int)offset {
    if (strings) {
        FBMutableArray *temp = strings;
        int length = (int)temp.count;
        if (length > 0) {
            NSString *item = nil;
            [self fb_set_offset:voffset value:offset];
            FBMutableData *data = [[FBMutableData alloc]initWithLength:length*4+4];
            [data setInt32:length offset:0];
            for (int i = 0 ; i < length ; i++) {
                item = (NSString*)temp[i];
                [data setInt32:(int32_t)(data.length-(4*i+4)) offset:i*4+4];
                [data appenddingString:item];
            }
            [self fb_add_data:[data data] offset:[self fb_offset:voffset]+bb_pos];
        }
    }
    return ;
}

- (void) fb_addTables:(FBMutableArray*)tables voffset:(int)voffset offset:(int)offset {
    if (tables) {
        FBMutableArray *temp = tables;
        int length = (int)temp.count;
        if (length > 0) {
            FBTable *item = nil;
            [self fb_set_offset:voffset value:offset];
            FBMutableData *data = [[FBMutableData alloc]initWithLength:length*4+4];
            [data setInt32:length offset:0];
            for (int i = 0 ; i < length ; i++) {
                item = (FBTable*)temp[i];
//                [data setInt32:(int32_t)(data.length-(4*i+4)) offset:i*4+4];
                [data setInt32:(int32_t)(data.length-(4*i+4)+item->bb_pos) offset:i*4+4];
                [data appendData:[item getData]];
            }
            [self fb_add_data:[data data] offset:[self fb_offset:voffset]+bb_pos];
        }
    }
    return ;
}


+ (BOOL) fb_has_identifier:(FBMutableData *)bb ident:(NSString *)ident {
    
    if (ident.length != FILE_IDENTIFIER_LENGTH){
        
        return NO;
        
    }
    
    NSString *tempStr = [bb stringWithOffset:0 length:FILE_IDENTIFIER_LENGTH];
    
    return [ident isEqualToString:tempStr];
}

@end
