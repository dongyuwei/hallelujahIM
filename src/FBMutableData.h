//
//  FBMutableData.h
//  flatbuf-objc
//
//  Created by SC on 16/5/18.
//  Copyright © 2016年 SC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FBMutableData : NSMutableData

- (BOOL)getBool:(int)offset;

- (int8_t)getInt8:(int)offset;

- (uint8_t)getUint8:(int)offset;

- (int16_t)getInt16:(int)offset;

- (uint16_t)getUint16:(int)offset;

- (int32_t)getInt32:(int)offset;

- (uint32_t)getUint32:(int)offset;

- (int64_t)getInt64:(int)offset;

- (uint64_t)getUint64:(int)offset;

- (float)getFloat:(int)offset;

- (double)getDouble:(int)offset;

- (NSString *)stringWithOffset:(int)offset length:(int)length;

- (void)setBool:(BOOL)value offset:(int)offset;

- (void)setInt8:(int8_t)value offset:(int)offset;

- (void)setUint8:(uint8_t)value offset:(int)offset;

- (void)setInt16:(int16_t)value offset:(int)offset;

- (void)setUint16:(uint16_t)value offset:(int)offset;

- (void)setInt32:(int32_t)value offset:(int)offset;

- (void)setUint32:(uint32_t)value offset:(int)offset;

- (void)setInt64:(int64_t)value offset:(int)offset;

- (void)setUint64:(uint64_t)value offset:(int)offset;

- (void)setFloat:(float)value offset:(int)offset;

- (void)setDouble:(double)value offset:(int)offset;

- (void)appenddingString:(NSString *)string;

- (void)appenddingData:(NSData *)data;

- (void)cutOffWithRange:(NSRange)range;

- (void)resetBytesInRange:(NSRange)range;

- (void)resetBytes;

- (const void *)bytes;

- (NSData*)data;

@end
