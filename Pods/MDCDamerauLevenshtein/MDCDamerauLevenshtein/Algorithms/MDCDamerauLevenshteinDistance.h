//
//  MDCDamerauLevenshteinDistance.h
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import <Foundation/Foundation.h>

/**
 Calculates the edit distance between two strings using the
 Damerau-Levenshtein distance algorithm.
 */
extern NSUInteger mdc_damerauLevenshteinDistance(NSString *left, NSString *right);