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
 * @header      NSBundle+GitHubUpdates.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @category    NSBundle( GitHubUpdates )
 * @abstract    Additional methods for NSBundle.
 */
@interface NSBundle( GitHubUpdates )

/*!
 * @property    isCodeSigned
 * @abstract    Checks if the bundle is code-signed.
 * @discussion  This will invoke the `codesign` utility.
 */
@property( nonatomic, readonly ) BOOL isCodeSigned;

/*!
 * @property    codeSigningIdentity
 * @abstract    Returns the identity used to code-sign the bundle, if any.
 * @discussion  This will invoke the `codesign` utility.
 */
@property( nonatomic, readonly, nullable ) NSString * codeSigningIdentity;

@end

NS_ASSUME_NONNULL_END
