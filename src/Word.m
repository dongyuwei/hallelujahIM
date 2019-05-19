// automatically generated, do not modify !!!

#import "Word.h"

@implementation Word 

- (NSString *) key {

    _key = [self fb_getString:4 origin:_key];

    return _key;

}

- (void) add_key {

    [self fb_addString:_key voffset:4 offset:4];

    return ;

}

- (int64_t) frequency {

    _frequency = [self fb_getInt64:6 origin:_frequency];

    return _frequency;

}

- (void) add_frequency {

    [self fb_addInt64:_frequency voffset:6 offset:8];

    return ;

}

- (NSString *) ipa {

    _ipa = [self fb_getString:8 origin:_ipa];

    return _ipa;

}

- (void) add_ipa {

    [self fb_addString:_ipa voffset:8 offset:16];

    return ;

}

- (FBMutableArray<NSString *> *) translation {

    _translation = [self fb_getStrings:10 origin:_translation];

    return _translation;

}

- (void) add_translation {

    [self fb_addStrings:_translation voffset:10 offset:20];

    return ;

}

- (instancetype)init{

    if (self = [super init]) {

        bb_pos = 18;

        origin_size = 24+bb_pos;

        bb = [[FBMutableData alloc]initWithLength:origin_size];

        [bb setInt32:bb_pos offset:0];

        [bb setInt32:12 offset:bb_pos];

        [bb setInt16:12 offset:bb_pos-[bb getInt32:bb_pos]];

        [bb setInt16:24 offset:bb_pos-[bb getInt32:bb_pos]+2];

    }

    return self;

}

@end
