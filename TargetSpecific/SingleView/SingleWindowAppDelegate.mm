//
//  SingleWindowAppDelegate.m
//  iAmiga
//
//  Created by Stuart Carnie on 6/21/11.
//  Copyright 2011 Manomio LLC. All rights reserved.
//
//  Changed by Emufr3ak on 29.05.14.
//
//  iUAE is free software: you may copy, redistribute
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 2 of the
//  License, or (at your option) any later version.
//
//  This file is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  General Public License for more details.
//
// You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#import "AdfImporter.h"
#import "SingleWindowAppDelegate.h"
#import "BaseEmulationViewController.h"
#import <AudioToolbox/AudioServices.h>
#import "SDL.h"
#import "UIKitDisplayView.h"
#import "SVProgressHUD.h"
#import "EMUROMBrowserViewController.h"

#import "sysconfig.h"
#import "sysdeps.h"
#import "options.h"

@interface SingleWindowAppDelegate()

- (void)screenDidConnect:(NSNotification*)aNotification;
- (void)screenDidDisconnect:(NSNotification*)aNotification;
- (void)configureScreens;

@end

@implementation SingleWindowAppDelegate

@synthesize window, mainController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    UINavigationController *navigationcontroller = (UINavigationController *)self.window.rootViewController;
    self.mainController = (BaseEmulationViewController *)navigationcontroller.topViewController;
    [window makeKeyAndVisible];
    window.frame = [[UIScreen mainScreen] bounds];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidConnect:) name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
    [self configureScreens];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    SDL_PauseOpenGL(1);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    SDL_PauseOpenGL(0);
}

- (void)screenDidConnect:(NSNotification*)aNotification {
	[self configureScreens];
}

- (void)screenDidDisconnect:(NSNotification*)aNotification {
	[self configureScreens];
	
}

- (void)configureScreens {
    
    [window.rootViewController setNeedsStatusBarAppearanceUpdate];
    
	if ([[UIScreen screens] count] == 1) {
		NSLog(@"Device display");
		// disable extras		
		if (externalWindow) {
			externalWindow.hidden = YES;
		}
        [mainController setDisplayViewWindow:nil isExternal:NO];
	} else {
		NSLog(@"External display");
		UIScreen *secondary = [[UIScreen screens] objectAtIndex:1];
		UIScreenMode *bestMode = [secondary.availableModes objectAtIndex:0];
		int modes = [secondary.availableModes count];
		if (modes > 1) {
			UIScreenMode *current;
			for (current in secondary.availableModes) {
				if (current.size.width > bestMode.size.width)
					bestMode = current;
			}
		}
		secondary.currentMode = bestMode;
		if (!externalWindow) {
			externalWindow = [[UIWindow alloc] initWithFrame:secondary.bounds];
			externalWindow.backgroundColor = [UIColor blackColor];
		} else {
			externalWindow.frame = secondary.bounds;
		}
        
		externalWindow.screen = secondary;
		[self.mainController setDisplayViewWindow:externalWindow isExternal:YES];
		externalWindow.hidden = NO;
	}
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    AdfImporter *importer = [[[AdfImporter alloc] init] autorelease];
    BOOL imported = [importer import:url.path];
    if (imported)
    {
        [SVProgressHUD setBackgroundColor:[UIColor lightGrayColor]];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Imported %@", [url.path lastPathComponent]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:[EMUROMBrowserViewController getAdfChangedNotificationName] object:nil];
    }
    else
    {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Failed to import %@", [url.path lastPathComponent]]];
    }
    return imported;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
