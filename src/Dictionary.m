// automatically generated, do not modify !!!

#import "Dictionary.h"

@implementation Dictionary 

- (FBMutableArray<Word *> *) entries {

    _entries = [self fb_getTables:4 origin:_entries className:[Word class]];

    return _entries;

}

- (void) add_entries {

    [self fb_addTables:_entries voffset:4 offset:4];

    return ;

}

- (instancetype)init{

    if (self = [super init]) {

        bb_pos = 12;

        origin_size = 8+bb_pos;

        bb = [[FBMutableData alloc]initWithLength:origin_size];

        [bb setInt32:bb_pos offset:0];

        [bb setInt32:6 offset:bb_pos];

        [bb setInt16:6 offset:bb_pos-[bb getInt32:bb_pos]];

        [bb setInt16:8 offset:bb_pos-[bb getInt32:bb_pos]+2];

    }

    return self;

}

@end
