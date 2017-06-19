/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Jean-David Gadina - www.xs-labs.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

/*!
 * @header      NSMutableAttributedString+GitHubUpdates.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @category    NSMutableAttributedString( GitHubUpdates )
 * @abstract    Additional methods for NSMutableAttributedString.
 */
@interface NSMutableAttributedString( GitHubUpdates )

/*!
 * @method      processMarker:attributes:
 * @abstract    Processes a marker, adding attributes if found.
 * @param       marker      The marker to process
 * @param       attributes  The attributes to use if the marker is found
 */
- ( void )processMarker: ( NSString * )marker attributes: ( NSDictionary * )attributes;

/*!
 * @method      processLineStart:attributes:
 * @abstract    Processes a line start marker, adding attributes if found.
 * @param       lineStart   The line start marker
 * @param       attributes  The attributes to use if the line start marker is found
 */
- ( void )processLineStart: ( NSString * )lineStart attributes: ( NSDictionary * )attributes;

@end

NS_ASSUME_NONNULL_END
