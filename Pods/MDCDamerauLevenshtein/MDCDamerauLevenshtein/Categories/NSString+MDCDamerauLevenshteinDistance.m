//
//  NSString+MDCDamerauLevenshteinDistance.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "NSString+MDCDamerauLevenshteinDistance.h"
#import "MDCDamerauLevenshteinDistance.h"

@implementation NSString (MDCDamerauLevenshteinDistance)

#pragma mark - Public Interface

+ (NSUInteger)mdc_damerauLevenshteinDistanceBetween:(NSString *)left and:(NSString *)right {
    return mdc_damerauLevenshteinDistance(left, right);
}

- (NSUInteger)mdc_damerauLevenshteinDistanceTo:(NSString *)string {
    return mdc_damerauLevenshteinDistance(self, string);
}

@end
