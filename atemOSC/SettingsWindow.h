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
	
	AppDelegate*                appDel;
}

- (void)loadSettingsFromPreferences;
- (void)showSwitcherConnected:(NSString *)switcherName;
- (void)showSwitcherDisconnected;
- (NSString *)switcherAddress;

@end
