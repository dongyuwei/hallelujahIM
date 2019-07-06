//
//  MDCDistanceMatrix.m
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import "MDCDistanceMatrix.h"

#pragma mark - Public Interface

MDCDistanceMatrix *MDCDistanceMatrixCreate(NSString *left, NSString *right) {
    MDCDistanceMatrix *matrix = malloc(sizeof(MDCDistanceMatrix));

    // Matrix height and width are padded by one
    // to make room for column and row indices.
    matrix->height = [left length] + 1;
    matrix->width = [right length] + 1;

    // Allocate memory for the matrix and initialize the rows to zero.
    size_t rowSize = matrix->width * sizeof(NSUInteger);
    matrix->distances = calloc(matrix->height, rowSize);
    for (NSUInteger y = 0; y < matrix->height; ++y) {
        matrix->distances[y] = calloc(1, rowSize);
    }

    // Set row and column indices.
    for (NSUInteger rowIndex = 1; rowIndex < matrix->height; ++rowIndex) {
        matrix->distances[rowIndex][0] = rowIndex;
    }
    for (NSUInteger columnIndex = 1; columnIndex < matrix->width; ++columnIndex) {
        matrix->distances[0][columnIndex] = columnIndex;
    }

    return matrix;
}

void MDCDistanceMatrixWalk(MDCDistanceMatrix *matrix, MDCDistanceMatrixWalker walker) {
    if (walker == nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"walker callback cannot be nil"];
    }

    for (NSUInteger y = 1; y < matrix->height; ++y) {
        for (NSUInteger x = 1; x < matrix->width; ++x) {
            walker(matrix, x, y);
        }
    }
}

void MDCDistanceMatrixDestroy(MDCDistanceMatrix *matrix) {
    for (NSUInteger y = 0; y < matrix->height; ++y) {
        free(matrix->distances[y]);
    }
    free(matrix->distances);

    free(matrix);
}

NSUInteger MDCDistanceMatrixCornerValue(MDCDistanceMatrix *matrix) {
    return matrix->distances[matrix->height-1][matrix->width-1];
}