//
//  Header.h
//  Pods
//
//  Created by Mathieu D'Amours on 5/8/13.
//
//

#pragma once


#define AssertKeyType(_key_)\
    NSParameterAssert([_key_ isKindOfClass:[NSString class]] || [_key_ isKindOfClass:[NSData class]])

#define SliceFromString(_string_)           leveldb::Slice((char *)[_string_ UTF8String], [_string_ lengthOfBytesUsingEncoding:NSUTF8StringEncoding])
#define StringFromSlice(_slice_)            [[[NSString alloc] initWithBytes:_slice_.data() length:_slice_.size() encoding:NSUTF8StringEncoding] autorelease]

#define SliceFromData(_data_)               leveldb::Slice((char *)[_data_ bytes], [_data_ length])
#define DataFromSlice(_slice_)              [NSData dataWithBytes:_slice_.data() length:_slice_.size()]

#define DecodeFromSlice(_slice_, _key_, _d) _d(_key_, DataFromSlice(_slice_))
#define EncodeToSlice(_object_, _key_, _e)  SliceFromData(_e(_key_, _object_))

#define KeyFromStringOrData(_key_)          ([_key_ isKindOfClass:[NSString class]]) ? SliceFromString(_key_) \
                                            : SliceFromData(_key_)

#define GenericKeyFromSlice(_slice_)        (LevelDBKey) { .data = _slice_.data(), .length = _slice_.size() }
#define GenericKeyFromNSDataOrString(_obj_) ([_obj_ isKindOfClass:[NSString class]]) ? \
                                                (LevelDBKey) { \
                                                    .data   = [_obj_ cStringUsingEncoding:NSUTF8StringEncoding], \
                                                    .length = [_obj_ lengthOfBytesUsingEncoding:NSUTF8StringEncoding] \
                                                } \
                                            :   (LevelDBKey) { \
                                                    .data = [_obj_ bytes], \
                                                    .length = [_obj_ length] \
                                                }
