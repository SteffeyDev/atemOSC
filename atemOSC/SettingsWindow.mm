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

	if ([prefs stringForKey:@"atem"])
		[mAddressTextField setStringValue:[prefs stringForKey:@"atem"]];

	if ([prefs stringForKey:@"oscdevice"])
		[mOscDeviceTextField setStringValue:[prefs objectForKey:@"oscdevice"]];

	if ([prefs integerForKey:@"outgoing"])
		[mOutgoingPortTextField setIntegerValue:[prefs integerForKey:@"outgoing"]];
	else
		[mOutgoingPortTextField setIntValue:4444];

	if ([prefs integerForKey:@"incoming"])
		[mIncomingPortTextField setIntegerValue:[prefs integerForKey:@"incoming"]];
	else
		[mIncomingPortTextField setIntValue:3333];
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
	NSTextField* textField = (NSTextField *)[aNotification object];
	
	if (textField == mOscDeviceTextField)
	{
		if ([self isValidIPAddress:[mOscDeviceTextField stringValue]])
			[prefs setObject:[mOscDeviceTextField stringValue] forKey:@"oscdevice"];
		else
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IPv4 Address for 'OSC Out IP Address'"];
			[alert beginSheetModalForWindow:[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] completionHandler:nil];
		}
	}
	
	if (textField == mAddressTextField)
	{
		if ([self isValidIPAddress:[mAddressTextField stringValue]])
		{
			// If we are already connected, and they want to connect to a different one, we need to make sure they didn't just accidently bump the keyboard
			if ([appDel isConnectedToATEM] && ![[textField stringValue] isEqualToString:[prefs stringForKey:@"atem"]])
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
					 }
					 else if ( returnCode == NSAlertSecondButtonReturn )
					 {
						 [mAddressTextField setStringValue:[prefs stringForKey:@"atem"]];
					 }
				 }];
			}
			else
			{
				[prefs setObject:[mAddressTextField stringValue] forKey:@"atem"];
			}
		}
		else if ([appDel isConnectedToATEM] || ![[mAddressTextField stringValue] isEqualToString:@""])
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IPv4 Address for 'Switcher IP Address'"];
			[alert beginSheetModalForWindow:[(AppDelegate *)[[NSApplication sharedApplication] delegate] window] completionHandler:nil];
			
			if ([appDel isConnectedToATEM])
				[mAddressTextField setStringValue:[prefs stringForKey:@"atem"]];
		}
	}
	
	// Only update if the input is valid and actually changed
	if (validInput)
		[appDel portChanged:[mIncomingPortTextField intValue] out:[mOutgoingPortTextField intValue] ip:[mOscDeviceTextField stringValue]];

	if (textField == mOutgoingPortTextField)
		[prefs setInteger:[mOutgoingPortTextField intValue] forKey:@"outgoing"];
	if (textField == mIncomingPortTextField)
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

- (void)updateLogLabel:(NSString *)message
{
	[mLogLabel setStringValue:message];
}

- (IBAction)viewLogButtonPressed:(id)sender
{
	NSInteger index = [logMenuOption.menu indexOfItem:logMenuOption];
	[logMenuOption.menu performActionForItemAtIndex:index];
}

- (IBAction)viewAddressesButtonPressed:(id)sender {
	NSInteger index = [addressesMenuOption.menu indexOfItem:addressesMenuOption];
	[addressesMenuOption.menu performActionForItemAtIndex:index];
}

@end
