//
//  SettingsWindow.h
//  AtemOSC
//
//  Created by Peter Steffey on 10/11/17.
//

#import <Cocoa/Cocoa.h>

@class AppDelegate;

@interface SettingsWindow : NSWindow<NSTextFieldDelegate>
{
	IBOutlet NSTextField*       mIncomingPortTextField;
	IBOutlet NSTextField*       mOutgoingPortTextField;
	IBOutlet NSTextField*       mOscDeviceTextField;
	
	IBOutlet NSLevelIndicator*  mRedLed;
	IBOutlet NSLevelIndicator*  mGreenLed;
	
	IBOutlet NSTextField*        mAddressTextField;
	IBOutlet NSTextField*        mSwitcherNameLabel;
	IBOutlet NSTextField*		 mLogLabel;
	
	AppDelegate*                appDel;
	IBOutlet NSMenuItem*		logMenuOption;
	IBOutlet NSMenuItem *addressesMenuOption;
}

- (void)loadSettingsFromPreferences;
- (void)showSwitcherConnected:(NSString *)switcherName;
- (void)showSwitcherDisconnected;
- (NSString *)switcherAddress;
- (void)updateLogLabel:(NSString *)message;
- (IBAction)viewLogButtonPressed:(id)sender;
- (IBAction)viewAddressesButtonPressed:(id)sender;

@end
