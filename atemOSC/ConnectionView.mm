//
//  ConnectionView.m
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import "ConnectionView.h"
#import "AppDelegate.h"

@implementation ConnectionView

@synthesize ipAddressTextField;
@synthesize productNameTextField;
@synthesize nicknameTextField;
@synthesize feedbackPortTextField;
@synthesize feedbackIpAddressTextField;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)loadFromSwitcher:(Switcher *)switcher;
{
	self->switcher = switcher;

	if (switcher.ipAddress)
		[ipAddressTextField setStringValue:switcher.ipAddress];
	else
		[ipAddressTextField setStringValue:@""];
	if (switcher.nickname)
		[nicknameTextField setStringValue:switcher.nickname];
	else
		[nicknameTextField setStringValue:@""];
	if (switcher.feedbackIpAddress)
		[feedbackIpAddressTextField setStringValue:switcher.feedbackIpAddress];
	else
		[feedbackIpAddressTextField setStringValue:@""];
	if (switcher.feedbackPort)
		[feedbackPortTextField setIntValue:switcher.feedbackPort];
	else
		[feedbackPortTextField setStringValue:@""];
}

- (void)reload
{
	[self loadFromSwitcher:switcher];
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
	BOOL validInput = YES;
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSTextField* textField = (NSTextField *)[aNotification object];
	
	if (textField == feedbackIpAddressTextField)
	{
		if ([self isValidIPAddress:[textField stringValue]])
		{
			[switcher setFeedbackIpAddress: [textField stringValue]];
			[switcher updateFeedback];
		}
		else
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IPv4 Address for 'OSC Out IP Address'"];
			[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:nil];
		}
	}
	
	if (textField == ipAddressTextField)
	{
		if ([self isValidIPAddress:[textField stringValue]])
		{
			// If we are already connected, and they want to connect to a different one, we need to make sure they didn't just accidently bump the keyboard
			if ([switcher isConnected] && ![[textField stringValue] isEqualToString:[prefs stringForKey:@"atem"]])
			{
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:@"Switcher Currently Connected"];
				[alert setInformativeText:[NSString stringWithFormat: @"Are you sure you want to disconnect from %@ and attempt to connect to %@?", [prefs stringForKey:@"atem"], [textField stringValue]]];
				[alert addButtonWithTitle:@"Yes (Connect to New)"];
				[alert addButtonWithTitle:@"No (Stay Connected)"];
				[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:^(NSInteger returnCode)
				 {
					 if ( returnCode == NSAlertFirstButtonReturn )
					 {
						 [switcher setIpAddress: [textField stringValue]];
						 [switcher switcherDisconnected];
					 }
					 else if ( returnCode == NSAlertSecondButtonReturn )
					 {
						 [ipAddressTextField setStringValue:switcher.ipAddress];
					 }
				 }];
			}
			else
			{
				[switcher setIpAddress: [textField stringValue]];
				[switcher switcherDisconnected];
			}
		}
		else if ([switcher isConnected] || ![[textField stringValue] isEqualToString:@""])
		{
			validInput = NO;
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid IP Adress"];
			[alert setInformativeText:@"Please enter a valid IPv4 Address for 'Switcher IP Address'"];
			[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:nil];
			
			if ([switcher isConnected])
				[textField setStringValue:switcher.ipAddress];
		}
	}
	
	if (textField == feedbackPortTextField)
	{
		[switcher setFeedbackPort: [textField intValue]];
		[switcher updateFeedback];
	}
	
	if (textField == nicknameTextField)
	{
		[switcher setNickname: [textField stringValue]];
	}
	
	// Only update if the input is valid and actually changed
	if (validInput)
	{
		[switcher saveChanges];
		
		Window *window = (Window *) [[NSApplication sharedApplication] mainWindow];
		[window refreshList];
	}
}

@end
