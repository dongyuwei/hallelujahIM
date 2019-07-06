//
//  MDCDistanceMatrix.h
//  MDCDamerauLevenshtein
//
//  Created by Brian Ivan Gesiak on 5/19/14.
//
//

#import <Foundation/Foundation.h>

/**
 A struct used to represent a distance matrix.
 Height and width values are stored upon creation.
 */
typedef struct {
    NSUInteger height;
    NSUInteger width;
    NSUInteger **distances;
} MDCDistanceMatrix;

/**
 A callback block used in the MDCDistanceMatrixWalk() function.
 */
typedef void (^MDCDistanceMatrixWalker)(MDCDistanceMatrix *matrix, NSUInteger x, NSUInteger y);

/**
 Creates and initializes a distance matrix.

 For example, to calculate a distance matrix between
 "boat" (4 letters) and "car" (3 letters), the following
 matrix is initialized:

 0 1 2 3  // Each column corresponds to a letter in "car".
 1 0 0 0  // There are 3, plus 1 for the row indices for "boat".
 2 0 0 0
 3 0 0 0  // Each row corresponds to a letter in "boat".
 4 0 0 0  // There are 4, plus 1 for the column indices for "car".

 You must call MDCDistanceMatrixDestroy on the matrix returned by
 this function in order to prevent a memory leak.
 */
extern MDCDistanceMatrix *MDCDistanceMatrixCreate(NSString *left, NSString *right);

/**
 Frees the memory used by a matrix. You must not reference the matrix
 pointer after calling this function.
 */
extern void MDCDistanceMatrixDestroy(MDCDistanceMatrix *matrix);

/**
 Traverses the matrix, excluding the row and column indices.
 This function raises an exception if the walker callback is nil.
 */
extern void MDCDistanceMatrixWalk(MDCDistanceMatrix *matrix, MDCDistanceMatrixWalker walker);

/**
 Returns the lower-right-most value in the distance matrix.
 */
extern NSUInteger MDCDistanceMatrixCornerValue(MDCDistanceMatrix *matrix);
