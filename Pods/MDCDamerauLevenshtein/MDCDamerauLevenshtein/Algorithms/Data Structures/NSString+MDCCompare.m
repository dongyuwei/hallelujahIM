//
//  NSString+MDCSubstring.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "NSString+MDCCompare.h"

@implementation NSString (MDCCompare)

#pragma mark - Public Interface

+ (BOOL)mdc_sameCharacterAtLeft:(NSString *)left index:(NSUInteger)leftIndex
                          right:(NSString *)right index:(NSUInteger)rightIndex {
    return [@([left characterAtIndex:leftIndex])
                compare:@([right characterAtIndex:rightIndex])] == NSOrderedSame;
}

@end
