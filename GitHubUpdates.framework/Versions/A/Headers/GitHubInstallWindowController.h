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
 * @header      GitHubInstallWindowController.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Cocoa/Cocoa.h>

@class GitHubRelease;
@class GitHubReleaseAsset;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       GitHubInstallWindowController
 * @abstract    Window controller for the install window.
 * @discussion  This window controller is used when an update is found, to
 *              propose the user to install it.
 */
@interface GitHubInstallWindowController: NSWindowController

/*!
 * @property    asset
 * @abstract    The asset proposed to be installed.
 * @see         GitHubReleaseAsset
 */
@property( atomic, readonly, strong, nullable ) GitHubReleaseAsset * asset;

/*!
 * @property    githubRelease
 * @abstract    The release proposed to be installed .
 * @see         GitHubRelease
 */
@property( atomic, readonly, strong, nullable ) GitHubRelease * githubRelease;

/*!
 * @property    installingUpdate
 * @abstract    Whether an update is currently beeing installed.
 */
@property( atomic, readonly ) BOOL installingUpdate;

/*!
 * @method      initWithAsset:release:
 * @abstract    Initializes an instance with an asset and a release.
 * @discussion  Although not marked as so, this method acts as the class'
 *              designated initializer.
 * @param       asset   The proposed asset
 * @param       release The proposed release
 * @result      The initialized instance
 * @see         GitHubReleaseAsset
 * @see         GitHubRelease
 */
- ( instancetype )initWithAsset: ( GitHubReleaseAsset * )asset release: ( GitHubRelease * )release;

@end

NS_ASSUME_NONNULL_END
