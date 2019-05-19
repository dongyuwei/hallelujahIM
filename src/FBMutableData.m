//
//  FBMutableData.m
//  flatbuf-objc
//
//  Created by SC on 16/5/18.
//  Copyright © 2016年 SC. All rights reserved.
//

#import "FBMutableData.h"
#import <arpa/inet.h>
#import <objc/runtime.h>

@interface FBMutableData ()

@property (nonatomic, strong) NSMutableData *parent;

@end


@implementation FBMutableData


- (instancetype)initWithData:(NSData *)data{
    
    self.parent = [[NSMutableData alloc]initWithData:data];
    
    return self;
    
}

- (instancetype)initWithCapacity:(NSUInteger)capacity{
    
    self.parent = [[NSMutableData alloc]initWithCapacity:capacity];
    
    return self;
    
}

-(instancetype)initWithLength:(NSUInteger)length{
    
    self.parent = [[NSMutableData alloc]initWithLength:length];
    
    return self;
}

- (void)appendData:(NSData *)other{
    
    [self.parent appendData:other];
    
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length{
    
    [self.parent appendBytes:bytes length:length];
    
}

-(NSData*)parent
{
    
    return objc_getAssociatedObject(self, @selector(parent));
    
}

-(void)setParent:(NSData *)parent
{

    objc_setAssociatedObject(self, @selector(parent), parent, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}


- (BOOL)getBool:(int)offset{
    
    int8_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0)];
    
    //    return ntohll(tempLong);
    return (BOOL)temp;
    
}

- (void)setBool:(BOOL)value offset:(int)offset{
    
    int8_t temp = (int8_t)value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0) withBytes:&temp];
    
    return ;
    
}

- (int8_t)getInt8:(int)offset{
    
    int8_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0)];
    
    //    return ntohll(tempLong);
    return temp;
    
}

- (void)setInt8:(int8_t)value offset:(int)offset{
    
    int8_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0) withBytes:&temp];
    
    return ;
    
}

- (uint8_t)getUint8:(int)offset{
    
    uint8_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0)];
    
    return temp;
    
}

- (void)setUint8:(uint8_t)value offset:(int)offset{
    
    uint8_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 1) ? 1 : 0) withBytes:&temp];
    
    return ;
    
}

- (int16_t)getInt16:(int)offset{
    
    int16_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 2) ? 2 : 0)];
    
    return temp;
    
}

- (void)setInt16:(int16_t)value offset:(int)offset{
    
    int16_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 2) ? 2 : 0) withBytes:&temp];
    
    return ;
    
}

- (uint16_t)getUint16:(int)offset{
    
    uint16_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 2) ? 2 : 0)];
    
    return temp;
    
}

- (void)setUint16:(uint16_t)value offset:(int)offset{
    
    uint16_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 2) ? 2 : 0) withBytes:&temp];
    
    return ;
    
}

- (int32_t)getInt32:(int)offset{
    
    int32_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0)];
    
    return temp;
    
}

- (void)setInt32:(int32_t)value offset:(int)offset{
    
    int32_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0) withBytes:&temp];
    
    return ;
    
}

- (uint32_t)getUint32:(int)offset{
    
    uint32_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0)];
    
    return temp;
    
}

- (void)setUint32:(uint32_t)value offset:(int)offset{
    
    uint32_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0) withBytes:&temp];
    
    return ;
    
}


- (int64_t)getInt64:(int)offset{
    
    int64_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0)];
    
    return temp;
    
}

- (void)setInt64:(int64_t)value offset:(int)offset{
    
    int64_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0) withBytes:&temp];
    
    return ;
    
}

- (uint64_t)getUint64:(int)offset{
    
    uint64_t temp = 0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0)];
    
    return temp;
    
}

- (void)setUint64:(uint64_t)value offset:(int)offset{
    
    uint64_t temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0) withBytes:&temp];
    
    return ;
    
}


- (float)getFloat:(int)offset{
    
    float temp = 0.0f;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0)];
    
    return temp;
    
}

- (void)setFloat:(float)value offset:(int)offset{
    
    float temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 4) ? 4 : 0) withBytes:&temp];
    
    return ;
    
}


- (double)getDouble:(int)offset{
    
    double temp = 0.0;
    
    [self.parent getBytes:&temp range:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0)];
    
    return temp;
    
}

- (void)setDouble:(double)value offset:(int)offset{
    
    double temp = value;
    
    [self.parent replaceBytesInRange:NSMakeRange(offset, self.parent.length  >= (offset + 8) ? 8 : 0) withBytes:&temp];
    
    return ;
    
}

- (NSString *)stringWithOffset:(int)offset length:(int)length{
    
    NSString *tempStr = nil;
    
    if ((offset+length) <= self.parent.length ) {
        
        tempStr = [[NSString alloc]initWithData:[self.parent subdataWithRange:NSMakeRange(offset, length)] encoding:NSUTF8StringEncoding];
    }
    
    return tempStr;
}

- (void)appenddingString:(NSString *)string{
    
    const char *tempStr = [string UTF8String];
    
    int32_t strLength = (int32_t)strlen(tempStr);
    
    [self.parent appendBytes:&strLength length:4];
    
    [self.parent appendBytes:tempStr length:strlen(tempStr)];
    
    return;
}

- (void)appenddingData:(NSData *)data{
    
    if (data && data.length > 0) {
        
        [self.parent appendData:data];
        
    }
    
    return;
}

- (NSData *)subdataWithRange:(NSRange)range{
    
    return [self.parent subdataWithRange:range];
    
}

- (NSUInteger)length{
    
    return self.parent.length;
    
}

- (void)cutOffWithRange:(NSRange)range{
    
    if ((range.location+range.length) <= self.parent.length){
        
        self.parent = [[NSMutableData alloc]initWithData:[self.parent subdataWithRange:range]];
    
    }
    
}

- (void)resetBytesInRange:(NSRange)range{
    range.location = range.location < self.parent.length ? range.location : self.parent.length-1;
    range.length   = range.length   < self.parent.length ? range.length   : self.parent.length;
    [self.parent resetBytesInRange:range];
}

- (void)resetBytes{
    
    [self.parent resetBytesInRange:NSMakeRange(0, self.parent.length)];
    
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes{
    
    [self.parent replaceBytesInRange:range withBytes:bytes];
    
}

- (const void *)bytes{
    
    return self.parent.bytes;
    
}


- (NSData*)data{
    
    return (NSData*)self.parent;
    
}

@end
