//
//  NSString+MDCSubstring.h
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MDCCompare)

/**
 Returns YES if the character at left[leftIndex] is equal to right[rightIndex],
 otherwise returns NO.
 */
+ (BOOL)mdc_sameCharacterAtLeft:(NSString *)left index:(NSUInteger)leftIndex
                          right:(NSString *)right index:(NSUInteger)rightIndex;

@end
