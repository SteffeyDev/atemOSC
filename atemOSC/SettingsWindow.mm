//
//  SettingsWindow.m
//  AtemOSC
//
//  Created by Peter Steffey on 10/11/17.
//

#import "SettingsWindow.h"
#import "AppDelegate.h"

@implementation SettingsWindow

- (void)loadSettingsFromPreferences
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[mAddressTextField setStringValue:[prefs stringForKey:@"atem"]];
	NSLog(@"Value: %@", [prefs stringForKey:@"atem"]);
	
	[mOutgoingPortTextField setIntValue:[prefs integerForKey:@"outgoing"]];
	[mIncomingPortTextField setIntValue:[prefs integerForKey:@"incoming"]];
	[mOscDeviceTextField setStringValue:[prefs objectForKey:@"oscdevice"]];
}

- (BOOL)isValidIPAddress:(NSString*) str
{
	const char *utf8 = [str UTF8String];
	int success;
	
	struct in_addr dst;
	success = inet_pton(AF_INET, utf8, &dst);
	if (success != 1) {
		struct in6_addr dst6;
		success = inet_pton(AF_INET6, utf8, &dst6);
	}
	
	return success == 1;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
	BOOL validInput = YES;
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if (![[mOscDeviceTextField stringValue] isEqualToString:@""])
	{
		if ([self isValidIPAddress:[mOscDeviceTextField stringValue]])
			[prefs setObject:[mOscDeviceTextField stringValue] forKey:@"oscdevice"];
		else
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IP Address for 'OSC Out IP Adress'"];
			[alert beginSheetModalForWindow:[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] completionHandler:nil];
		}
	}
	
	if (![[mAddressTextField stringValue] isEqualToString:@""])
	{
		if ([self isValidIPAddress:[mAddressTextField stringValue]])
		{
			// If we are already connected, and they want to connect to a different one, we need to make sure they didn't just accidently bump the keyboard
			NSTextField* textField = (NSTextField *)[aNotification object];
			if (textField == mAddressTextField && [appDel isConnectedToATEM] && ![[textField stringValue] isEqualToString:[prefs stringForKey:@"atem"]])
			{
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:@"Switcher Currently Connected"];
				[alert setInformativeText:[NSString stringWithFormat: @"Are you sure you want to disconnect from %@ and attempt to connect to %@?", [prefs stringForKey:@"atem"], [textField stringValue]]];
				[alert addButtonWithTitle:@"Yes (Connect to New)"];
				[alert addButtonWithTitle:@"No (Stay Connected)"];
				[alert beginSheetModalForWindow:[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] completionHandler:^(NSInteger returnCode)
				 {
					 if ( returnCode == NSAlertFirstButtonReturn )
					 {
						 [prefs setObject:[mAddressTextField stringValue] forKey:@"atem"];
						 [appDel switcherDisconnected];
						 [appDel connectBMD];
					 }
					 else if ( returnCode == NSAlertSecondButtonReturn )
					 {
						 NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
						 [mAddressTextField setStringValue:[prefs stringForKey:@"atem"]];
					 }
				 }];
			}
			else
			{
				[prefs setObject:[mAddressTextField stringValue] forKey:@"atem"];
			}
		}
		else
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IP Address for 'Switcher IP Adress'"];
			[alert beginSheetModalForWindow:[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] completionHandler:nil];
		}
	}
	
	if (validInput)
		[appDel portChanged:[mIncomingPortTextField intValue] out:[mOutgoingPortTextField intValue] ip:[mOscDeviceTextField stringValue]];
	
	[prefs setInteger:[mOutgoingPortTextField intValue] forKey:@"outgoing"];
	[prefs setInteger:[mIncomingPortTextField intValue] forKey:@"incoming"];
	[prefs synchronize];
}

- (void)showSwitcherConnected:(NSString *)switcherName
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[mSwitcherNameLabel setStringValue:switcherName];
		[switcherName release];
		[mGreenLed setHidden:NO];
		[mRedLed setHidden:YES];
	});
}

- (void)showSwitcherDisconnected
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[mSwitcherNameLabel setStringValue:@""];
		[mGreenLed setHidden:YES];
		[mRedLed setHidden:NO];
	});
}

- (NSString *)switcherAddress
{
	return [mAddressTextField stringValue];
}

@end
