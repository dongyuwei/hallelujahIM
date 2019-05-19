//
//  FBConstants.h
//  flatbuf-objc
//
//  Created by SC on 16/5/18.
//  Copyright © 2016年 SC. All rights reserved.
//

#ifndef FBConstants_h
#define FBConstants_h

#define SIZEOF_SHORT 2

#define SIZEOF_INT 4

#define FILE_IDENTIFIER_LENGTH 4

typedef NS_ENUM(NSInteger, FBNumberType) {
    FBNumberBool = 0,
    FBNumberChar,
    FBNumberUChar,
    FBNumberInt8,
    FBNumberUint8,
    FBNumberInt16,
    FBNumberUint16,
    FBNumberInt32,
    FBNumberUint32,
    FBNumberInt64,
    FBNumberUint64,
    FBNumberFloat,
    FBNumberDouble
};


#endif /* FBConstants_h */
