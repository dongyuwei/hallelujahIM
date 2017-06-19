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
 * @header      GitHubReleaseAsset.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Foundation/Foundation.h>

@class GitHubRelease;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       GitHubRelease 
 * @abstract    Represents a GitHub release's asset.
 */
@interface GitHubReleaseAsset: NSObject

/*!
 * @property    url
 * @abstract    The asset's URL.
 * @discussion  This URL corresponds to the asset API feed URL.
 * @see         downloadURL
 */
@property( atomic, readonly, strong, nullable ) NSURL * url;

/*!
 * @property    downloadURL
 * @abstract    The asset's download URL.
 */
@property( atomic, readonly, strong, nullable ) NSURL * downloadURL;

/*!
 * @property    name
 * @abstract    The asset's name.
 */
@property( atomic, readonly, strong, nullable ) NSString * name;

/*!
 * @property    contentType
 * @abstract    The asset's content type.
 */
@property( atomic, readonly, strong, nullable ) NSString * contentType;

/*!
 * @property    created
 * @abstract    The asset's creation date.
 */
@property( atomic, readonly, strong, nullable ) NSDate * created;

/*!
 * @property    updated
 * @abstract    The asset's update date, if any.
 */
@property( atomic, readonly, strong, nullable ) NSDate * updated;

/*!
 * @property    size
 * @abstract    The asset's size.
 */
@property( atomic, readonly ) NSUInteger size;

/*!
 * @method      initWithDictionary:
 * @abstract    Initializes an instance with properties from a dictionary.
 * @param       dict    The dictionary containing the asset's properties
 * @result      The initialized instance, or nil
 */
- ( nullable instancetype )initWithDictionary: ( NSDictionary * )dict;

@end

NS_ASSUME_NONNULL_END
