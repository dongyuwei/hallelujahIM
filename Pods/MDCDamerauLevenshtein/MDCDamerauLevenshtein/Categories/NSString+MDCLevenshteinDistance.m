//
//  NSString+MDCLevenshteinDistance.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "NSString+MDCLevenshteinDistance.h"
#import "MDCLevenshteinDistance.h"

@implementation NSString (MDCLevenshteinDistance)

#pragma mark - Public Interface

+ (NSUInteger)mdc_levenshteinDistanceBetween:(NSString *)left and:(NSString *)right {
    return mdc_levenshteinDistance(left, right);
}

- (NSUInteger)mdc_levenshteinDistanceTo:(NSString *)string {
    return mdc_levenshteinDistance(self, string);
}

@end
