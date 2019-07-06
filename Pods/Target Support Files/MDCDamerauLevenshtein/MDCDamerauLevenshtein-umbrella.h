#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MDCDamerauLevenshtein.h"
#import "NSString+MDCDamerauLevenshteinDistance.h"
#import "NSString+MDCLevenshteinDistance.h"

FOUNDATION_EXPORT double MDCDamerauLevenshteinVersionNumber;
FOUNDATION_EXPORT const unsigned char MDCDamerauLevenshteinVersionString[];

