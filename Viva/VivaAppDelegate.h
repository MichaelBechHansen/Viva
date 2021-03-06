//
//  VivaAppDelegate.h
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LoginWindowController.h"
#import "MainWindowController.h"
#import "VivaPlaybackManager.h"
#import "SPMediaKeyTap.h"
#import <Growl/Growl.h>

@interface VivaAppDelegate : NSObject <NSApplicationDelegate, SPSessionDelegate, GrowlApplicationBridgeDelegate> {
@private
    NSWindow *__unsafe_unretained window;
	LoginWindowController *loginWindowController;
	MainWindowController *mainWindowController;
	VivaPlaybackManager *playbackManager;
	NSMenu *__weak dockMenu;
	SPMediaKeyTap *mediaKeyHandler;
	NSURL *urlToHandleOnLogin;
}

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (strong, readonly) VivaPlaybackManager *playbackManager; 
@property (weak) IBOutlet NSMenu *dockMenu;
@property (strong, readonly) SPMediaKeyTap *mediaKeyHandler;
@property (weak, readonly) SPSession *session;
@property (strong, readonly) NSURL *urlToHandleOnLogin;
@property (weak) IBOutlet NSMenu *visualizersMenu;

-(void)handleURL:(NSURL *)url;
-(void)logOut;

// For Applescript, Dock menu, etc
-(IBAction)performNextTrackAction:(id)sender;
-(IBAction)performSeekForwardABitAction:(id)sender;
-(IBAction)performPreviousTrackAction:(id)sender;
-(IBAction)performSeekBackwardABitAction:(id)sender;
-(IBAction)performPlayPauseAction:(id)sender;
-(IBAction)performVolumeUpAction:(id)sender;
-(IBAction)performVolumeDownAction:(id)sender;
-(IBAction)toggleVisualizer:(id)sender;

@end
