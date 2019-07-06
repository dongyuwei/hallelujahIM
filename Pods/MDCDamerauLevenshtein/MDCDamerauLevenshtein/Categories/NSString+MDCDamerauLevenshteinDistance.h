//
//  NSString+MDCDamerauLevenshteinDistance.h
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MDCDamerauLevenshteinDistance)

/**
 Returns the edit distance between two strings, calculated using the
 Damerau-Levenshtein distance algorithm.

 The Damerau-Levenshtein algorithm calculates edit distance of two strings as the number of
 insertions, deletions, substitions, and transpositions necessary in order to convert one string
 into the other. The addition of transpositions to the set of available operations differentiates
 it from the Levenshtein algorithm.

 The time complexity of the algorithm has an upper bound of `O(n^2)`,
 where `n` is `MAX([left length], [right length])`.

 @param left One of the strings to be compared. This must not be nil.
 @param right Another of the strings to be compared. This must not be nil.
 @return The edit distance between the two strings. If one of the strings is empty, the length of the other string is returned. If both are empty, zero is returned.
 */
+ (NSUInteger)mdc_damerauLevenshteinDistanceBetween:(NSString *)left and:(NSString *)right;

/**
 Returns the edit distance between the subject and the string parameter, calculated
 using the Damerau-Levenshtein distance algorithm. See
 `+[NSString mdc_damerauLevenshteinDistanceBetween:and:]` for details on the algorithm.

 @param string The string against which the subject is compared. This must not be nil.
 @return The edit distance between the two strings. If the string parameter is an empty string, the length of the subject returned. If both are empty, zero is returned.
 */
- (NSUInteger)mdc_damerauLevenshteinDistanceTo:(NSString *)string;

@end
