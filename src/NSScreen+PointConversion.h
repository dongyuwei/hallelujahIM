//
//  NSScreen+PointConversion.h
//  ColorPicker
//
//  Created by Oscar Del Ben on 9/5/11.
//  Copyright 2011 DibiStore. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSScreen (PointConversion)

/* 
 Returns the screen where the mouse resides
*/
+ (NSScreen *)currentScreenForMouseLocation;

/*
 Allows you to convert a point from global coordinates to the current screen coordinates.
*/
- (NSPoint)convertPointToScreenCoordinates:(NSPoint)aPoint;

/*
 Allows to flip the point coordinates, so y is 0 at the top instead of the bottom. x remains the same
*/
- (NSPoint)flipPoint:(NSPoint)aPoint;

@end
