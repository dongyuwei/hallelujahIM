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
 * @header      GitHubRelease.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Foundation/Foundation.h>

@class GitHubReleaseAsset;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       GitHubRelease 
 * @abstract    Represents a GitHub release.
 */
@interface GitHubRelease: NSObject

/*!
 * @property    url
 * @abstract    The release URL.
 * @discussion  This URL corresponds to the release API feed URL.
 * @see         htmlURL
 */
@property( atomic, readonly, strong, nullable ) NSURL * url;

/*!
 * @property    htmlURL
 * @abstract    The web URL for the release.
 */
@property( atomic, readonly, strong, nullable ) NSURL * htmlURL;

/*!
 * @property    tagName
 * @abstract    The name of the release's tag.
 */
@property( atomic, readonly, strong, nullable ) NSString * tagName;

/*!
 * @property    draft
 * @abstract    Whether this release is a draft.
 */
@property( atomic, readonly ) BOOL draft;

/*!
 * @property    draft
 * @abstract    Whether this release is a prerelease.
 */
@property( atomic, readonly ) BOOL prerelease;

/*!
 * @property    created
 * @abstract    The release's creation date.
 */
@property( atomic, readonly, strong, nullable ) NSDate * created;

/*!
 * @property    published
 * @abstract    The release's publication date.
 */
@property( atomic, readonly, strong, nullable ) NSDate * published;

/*!
 * @property    tarballURL
 * @abstract    The URL for the source code's TAR archive.
 */
@property( atomic, readonly, strong, nullable ) NSURL * tarballURL;

/*!
 * @property    zipballURL
 * @abstract    The URL for the source code's ZIP archive.
 */
@property( atomic, readonly, strong, nullable ) NSURL * zipballURL;

/*!
 * @property    body
 * @abstract    The release notes for the release.
 */
@property( atomic, readonly, strong, nullable ) NSString * body;

/*!
 * @property    assets
 * @abstract    The assets contained in the release.
 * @see         GitHubReleaseAsset
 */
@property( atomic, readonly, strong, nullable ) NSArray< GitHubReleaseAsset * > * assets;

/*!
 * @method      releasesWithData:error:
 * @abstract    Gets an array of releases from JSON data.
 * @result      The initialized instance
 * @param       data    The JSON data
 * @param       error   An optional pointer to an error object
 */
+ ( nullable NSArray< GitHubRelease * > * )releasesWithData: ( NSData * )data error: ( NSError * __autoreleasing * )error;

@end

NS_ASSUME_NONNULL_END
