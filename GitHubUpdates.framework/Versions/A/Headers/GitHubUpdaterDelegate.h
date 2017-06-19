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
 * @header      GitHubUpdaterDelegate.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Cocoa/Cocoa.h>

@class GitHubUpdater;
@class GitHubRelease;
@class GitHubVersion;
@class GitHubProgressWindowController;
@class GitHubInstallWindowController;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @protocol    GitHubUpdaterDelegate
 * @abstract    Optional delegate for GitHubUpdater.
 * @see         GitHubUpdater
 */
@protocol GitHubUpdaterDelegate< NSObject >

@optional

/*!
 * @method      updaterShouldCheckForDrafts:
 * @abstract    Implement if you need to check for draft updates.
 * @param       updater The updater object
 * @result      YES if the updater should check for draft updates, otherwise NO
 */
- ( BOOL )updaterShouldCheckForDrafts: ( GitHubUpdater * )updater;

/*!
 * @method      updaterShouldCheckForPrereleases:
 * @abstract    Implement if you need to check for prerelease updates.
 * @param       updater The updater object
 * @result      YES if the updater should check for prerelease updates, otherwise NO
 */
- ( BOOL )updaterShouldCheckForPrereleases: ( GitHubUpdater * )updater;

/*!
 * @method      updaterShouldCheckForUpdatesInBackground:
 * @abstract    Whether the updater is allowed to check for updates in background.
 * @discussion  By implementing this method, you can control if the updater can
 *              check for updates in background.
 *              This method has no effect on user-initiated update checks, using
 *              `- [ GitHubUpdater checkForUpdates: ]`. It will only be able to
 *              control `- [ GitHubUpdater checkForUpdatesInBackground ]`.
 * @param       updater The updater object
 * @result      YES if the updater should check for updates in background, otherwise NO
 */
- ( BOOL )updaterShouldCheckForUpdatesInBackground: ( GitHubUpdater * )updater;

/*!
 * @method      classForUpdaterProgressWindowController:
 * @abstract    Returns the class to use for the progress window controller.
 * @discussion  This allows you to specify a custom class for the progress
 *              window controller, if you need customization.
 *              Note that the returned class must inherit from
 *              `GitHubProgressWindowController`.
 * @param       updater The updater object
 * @result      The class to use
 */
- ( Class )classForUpdaterProgressWindowController: ( GitHubUpdater * )updater;

/*!
 * @method      classForUpdaterInstallWindowController:
 * @abstract    Returns the class to use for the install window controller.
 * @discussion  This allows you to specify a custom class for the install
 *              window controller, if you need customization.
 *              Note that the returned class must inherit from
 *              `GitHubInstallWindowController`.
 * @param       updater The updater object
 * @result      The class to use
 */
- ( Class )classForUpdaterInstallWindowController: ( GitHubUpdater * )updater;

/*!
 * @method      updater:urlForUpdatesWithUser:repository:proposedURL:
 * @abstract    Returns the URL for the update check.
 * @discussion  You may implement this if you need to customize the update
 *              URL, for instance if you use another servcie than GitHub.
 * @param       updater     The updater object
 * @param       user        The user name
 * @param       repository  The repository name
 * @param       proposedURL The proposed, default URL
 */
- ( NSURL * )updater: ( GitHubUpdater * )updater urlForUpdatesWithUser: ( NSString * )user repository: ( NSString * )repository proposedURL: ( NSURL * )proposedURL;

/*!
 * @method      updater:releasesWithData:error:
 * @abstract    Gets releases from a data object
 * @discussion  You may implement this method if you need to customize the
 *              parsing of updates data, with a different behaviour than
 *              using JSON data from GitHub releases.
 * @param       updater The updater object
 * @param       data    The data object fetched from the update URL
 * @param       error   An optional pointer to an error object
 * @result      An array of release objects, if any
 */
- ( nullable NSArray< GitHubRelease * > * )updater: ( GitHubUpdater * )updater releasesWithData: ( NSData * )data error: ( NSError * __autoreleasing * )error;

/*!
 * @method      updater:versionForRelease:
 * @abstract    Gets a version object for a release.
 * @discussion  You may implement this method if you need to customize the
 *              way version numbers are created from releases.
 *              If not implemented, the tag name will be used as version
 *              number.
 * @param       updater The updater object
 * @param       release The release object
 * @result      A version object for the release
 */
- ( GitHubVersion * )updater: ( GitHubUpdater * )updater versionForRelease: ( GitHubRelease * )release;

/*!
 * @method      updater:version:isNewerThanVersion:
 * @abstract    Determines if a version is newer than another version
 * @discussion  You may implement this method if you need to customize the
 *              way versions are compared.
 * @param       updater The updater object
 * @param       v1      The first version
 * @param       v2      The second version
 * @result      YES if the first version is newer, otherwise NO
 */
- ( BOOL )updater: ( GitHubUpdater * )updater version: ( GitHubVersion * )v1 isNewerThanVersion: ( GitHubVersion * )v2;

/*!
 * @method      updater:willShowProgressWindowController:
 * @abstract    Called when the updater is about to show a progress window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater willShowProgressWindowController: ( GitHubProgressWindowController * )controller;

/*!
 * @method      updater:willShowInstallWindowController:
 * @abstract    Called when the updater is about to show an install window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater willShowInstallWindowController: ( GitHubInstallWindowController * )controller;

/*!
 * @method      updater:didShowProgressWindowController:
 * @abstract    Called when the updater has shown a progress window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater didShowProgressWindowController: ( GitHubProgressWindowController * )controller;

/*!
 * @method      updater:didShowProgressWindowController:
 * @abstract    Called when the updater has shown an install window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater didShowInstallWindowController: ( GitHubInstallWindowController * )controller;

/*!
 * @method      updater:willCloseProgressWindowController:
 * @abstract    Called when the updater is about to close a progress window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater willCloseProgressWindowController: ( GitHubProgressWindowController * )controller;

/*!
 * @method      updater:willCloseInstallWindowController:
 * @abstract    Called when the updater is about to close an install window.
 * @param       updater     The updater object
 * @param       controller  The window controller
 */
- ( void )updater: ( GitHubUpdater * )updater willCloseInstallWindowController: ( GitHubInstallWindowController * )controller;

/*!
 * @method      updater:willDisplayAlert:withError:
 * @abstract    Called when the updater is about to display an error alert.
 * @param       updater The updater object
 * @param       alert   The alert object
 * @param       error   The error object
 */
- ( void )updater: ( GitHubUpdater * )updater willDisplayAlert: ( NSAlert * )alert withError: ( NSError * )error;

/*!
 * @method      updater:willDisplayUpToDateAlert:
 * @abstract    Called when the updater is about to display an up-to-date alert.
 * @param       updater The updater object
 * @param       alert   The alert object
 */
- ( void )updater: ( GitHubUpdater * )updater willDisplayUpToDateAlert: ( NSAlert * )alert;

@end

NS_ASSUME_NONNULL_END
