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
 * @header      GitHubUpdater.h
 * @copyright   (c) 2017, Jean-David Gadina - www.xs-labs.com
 */

#import <Foundation/Foundation.h>
#import <GitHubUpdates/GitHubUpdaterDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       GitHubUpdater
 * @abstract    GitHub updater class.
 * @discussion  This is the class you'll need to create in order to check for
 *              GitHub updates.
 *              Note that this class can be instanciated using InterfaceBuilder
 *              as well.
 */
@interface GitHubUpdater: NSObject

/*!
 * @property    user
 * @abstract    Your GitHub user name.
 */
@property( atomic, readwrite, strong ) IBInspectable NSString * user;

/*!
 * @property    repository
 * @abstract    Your GitHub repository.
 */
@property( atomic, readwrite, strong ) IBInspectable NSString * repository;

/*!
 * @property    delegate
 * @abstract    The delegate object, if you need behaviour customization.
 * @see         GitHubUpdaterDelegate
 */
@property( atomic, readwrite, weak ) id< GitHubUpdaterDelegate > delegate;

/*!
 * @property    checkingForUpdates
 * @abstract    Whether the updater is currently checking for updates.
 */
@property( atomic, readonly ) BOOL checkingForUpdates;

/*!
 * @property    installingUpdate
 * @abstract    Whether the updater is currently installing an update.
 */
@property( atomic, readonly ) BOOL installingUpdate;

/*!
 * @method      checkForUpdates:
 * @abstract    Checks for updates.
 " @discussion  This method will display a progress window while checking for
 *              updates.
 *              If an update is found, it will present the user with a window
 *              proposing to install the new update.
 * @param       sender  An optional sender. Not used.
 */
- ( IBAction )checkForUpdates: ( nullable id )sender;

/*!
 * @method      checkForUpdatesInBackground
 * @abstract    Checks for updates in background.
 " @discussion  This method won't display any UI.
 *              If an update is found, it will present the user with a window
 *              proposing to install the new update.
 */
- ( void )checkForUpdatesInBackground;

@end

NS_ASSUME_NONNULL_END
