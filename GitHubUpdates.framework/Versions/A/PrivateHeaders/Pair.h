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
 * @header      Pair.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       Pair
 * @abstract    Represents an object pair.
 */
@interface Pair< FirstType, SecondType >: NSObject

/*!
 * @property    first
 * @abstract    The first object in the pair.
 */
@property( atomic, readwrite, strong, nullable ) FirstType first;

/*!
 * @property    second
 * @abstract    The second object in the pair.
 */
@property( atomic, readwrite, strong, nullable ) SecondType second;

/*!
 * @method      initWithFirstValue:secondValue:
 * @abstract    Initialized an instance of this class.
 * @discussion  This is the class's designated initializer.
 * @result      The initialized instance
 * @param       v1  The first object
 * @param       v2  The second object
 */
- ( instancetype )initWithFirstValue: ( nullable FirstType )v1 secondValue: ( nullable SecondType )v2 NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
