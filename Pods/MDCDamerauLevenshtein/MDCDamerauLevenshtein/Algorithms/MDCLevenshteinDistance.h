//
//  MDCLevenshteinDistance.h
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import <Foundation/Foundation.h>

/**
 Calculates the edit distance between two strings using the Levenshtein
 distance algorithm.
 */
extern NSUInteger mdc_levenshteinDistance(NSString *left, NSString *right);

/**
 Performs the following sanity checks on the arguments passed to a
 distance function like mdc_levenshteinDistance:
 
 1. Raises an exception if either left or right is nil.
 2. If right is lexicographically larger than left, swaps the two.

 */
extern void mdc_normalizeDistanceParameters(NSString **left, NSString **right);
