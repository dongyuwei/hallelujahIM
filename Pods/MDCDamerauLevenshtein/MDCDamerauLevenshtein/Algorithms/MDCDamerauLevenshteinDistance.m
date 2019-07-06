//
//  MDCDamerauLevenshteinDistance.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "MDCDamerauLevenshteinDistance.h"
#import "MDCLevenshteinDistance.h"
#import "MDCDistanceMatrix.h"
#import "NSString+MDCCompare.h"

#pragma mark - Public Interface

extern NSUInteger mdc_damerauLevenshteinDistance(NSString *left, NSString *right) {
    mdc_normalizeDistanceParameters(&left, &right);
    if ([right length] == 0) {
        return [left length];
    }

    MDCDistanceMatrix *matrix = MDCDistanceMatrixCreate(left, right);
    MDCDistanceMatrixWalk(matrix, ^(MDCDistanceMatrix *matrix, NSUInteger x, NSUInteger y) {
        // Calculation of deletion, insertion, and substituion costs is
        // identical to the Levenshtein algorithm.
        NSUInteger cost = [NSString mdc_sameCharacterAtLeft:left index:y-1 right:right index:x-1] ? 0 : 1;
        NSUInteger deletion = matrix->distances[y-1][x] + 1;
        NSUInteger insertion = matrix->distances[y][x-1] + 1;
        NSUInteger substitution = matrix->distances[y-1][x-1] + cost;

        // Damerau also accounts for transposition of adjacent characters.
        //
        // Check if both:
        //   a) the current left chatacter is the same as the previous right character, and
        //   b) the previous left character is the same as the current right character
        //
        // If so, we can swap the two. Note that if the four characters were the all
        // the same in the first place (i.e.: the "ll" in "hello" and "hello"),
        // we don't want to increment the edit distance; hence we add `cost`, not 1.
        NSUInteger transposition = NSUIntegerMax;
        if (x > 1 && y > 1 && [NSString mdc_sameCharacterAtLeft:left index:y-1 right:right index:x-2] &&
            [NSString mdc_sameCharacterAtLeft:left index:y-2 right:right index:x-1]) {
            transposition = matrix->distances[y-2][x-2] + cost;
        }

        matrix->distances[y][x] = MIN(MIN(MIN(insertion, deletion), substitution), transposition);
    });

    NSUInteger distance = MDCDistanceMatrixCornerValue(matrix);
    MDCDistanceMatrixDestroy(matrix);
    return distance;
}
