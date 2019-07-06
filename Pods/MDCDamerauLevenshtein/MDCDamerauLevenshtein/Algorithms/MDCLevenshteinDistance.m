//
//  MDCLevenshteinDistance.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "MDCLevenshteinDistance.h"
#import "MDCDistanceMatrix.h"
#import "NSString+MDCCompare.h"

#pragma mark - Public Interface

NSUInteger mdc_levenshteinDistance(NSString *left, NSString *right) {
    mdc_normalizeDistanceParameters(&left, &right);
    if ([right length] == 0) {
        return [left length];
    }

    MDCDistanceMatrix *matrix = MDCDistanceMatrixCreate(left, right);
    MDCDistanceMatrixWalk(matrix, ^(MDCDistanceMatrix *matrix, NSUInteger x, NSUInteger y){
        // Each element in the matrix corresponds to the distance between
        // the two strings. For example, with "car" and "boat", the matrix
        // for the first characters of each would look like this:
        //
        //     0 c
        //     b 0
        //
        // The distance it would take to turn "c" into "b" via deletion is
        // the distance it would take to turn "b" into "bc" (1 by insertion),
        // plus one to delete the extra character.
        NSUInteger deletion = matrix->distances[y-1][x] + 1;

        // The distance it would take to turn "c" into "b" via insertion is
        // the cost of turning "c" into "" (1 by deletion), plus one.
        NSUInteger insertion = matrix->distances[y][x-1] + 1;

        // If the two characters are the same, there is no substituion cost,
        // so the distance is equivalent to the distance between the two previous
        // strings (the upper-left element in the matrix).
        NSUInteger substitution = matrix->distances[y-1][x-1];

        // But if they're different, the distance is the previous distance plus one.
        // The matrix is padded with row and column indices, so we must decrement
        // x and y when accessing characters in the string.
        if (![NSString mdc_sameCharacterAtLeft:left index:y-1 right:right index:x-1]) {
            ++substitution;
        }

        // We're interested in the most efficient edit distance, so use the minimum
        // of the three calculated costs.
        matrix->distances[y][x] = MIN(MIN(insertion, deletion), substitution);
    });

    // The corner value is the optimal distance between the two entire strings.
    NSUInteger distance = MDCDistanceMatrixCornerValue(matrix);
    MDCDistanceMatrixDestroy(matrix);
    return distance;
}

void mdc_normalizeDistanceParameters(NSString **left, NSString **right) {
    if (*left == nil || *right == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot compute edit distance between strings: '%@' and '%@'",
         *left, *right];
    }

    if ([*left compare:*right] == NSOrderedDescending) {
        NSString *tmp = *left;
        *left = *right;
        *right = tmp;
    }
}
