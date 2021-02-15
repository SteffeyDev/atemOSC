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
@synthesize connectButton;
@synthesize connectAutomaticallyButton;

@synthesize switcher;

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
	
	if (switcher.connectAutomatically)
		[connectAutomaticallyButton setState:NSControlStateValueOn];
	else
		[connectAutomaticallyButton setState:NSControlStateValueOff];
	
	[productNameTextField setStringValue:@""];
	if ([[switcher connectionStatus] isEqualToString: @"Connecting"])
	{
		[ipAddressTextField setEnabled:NO];
		[connectButton setEnabled:NO];
		[connectButton setTitle:@"Connecting"];
	}
	else if ([switcher isConnected])
	{
		[ipAddressTextField setEnabled:NO];
		[connectButton setEnabled:YES];
		[connectButton setTitle:@"Disconnect"];
		[productNameTextField setStringValue:[switcher productName]];
	}
	else if ([switcher ipAddress] != nil && [self isValidIPAddress:switcher.ipAddress])
	{
		[ipAddressTextField setEnabled:YES];
		[connectButton setEnabled:YES];
		[connectButton setTitle:@"Connect"];
	}
	else
	{
		[ipAddressTextField setEnabled:YES];
		[connectButton setEnabled:NO];
		[connectButton setTitle:@"Connect"];
	}
}

- (IBAction)connectButtonPressed:(id)sender {
	if ([switcher isConnected])
	{
		[switcher disconnectBMD];
	}
	else
	{
		if ([self isValidIPAddress:[ipAddressTextField stringValue]] && ![[switcher connectionStatus] isEqualToString:@"Connecting"])
		{
			[switcher setIpAddress: [ipAddressTextField stringValue]];
			[switcher saveChanges];
			[switcher connectBMD];
		}
		[connectButton setEnabled:NO];
	}
}

- (IBAction)connectAutomaticallyButtonPressed:(id)sender
{
	[switcher setConnectAutomatically:[connectAutomaticallyButton state] == NSControlStateValueOn];
	[switcher saveChanges];
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

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField* textField = (NSTextField *)[notification object];
	
	// Only allow connect if IP address is valid
	if (textField == ipAddressTextField)
	{
		[[self connectButton] setEnabled:[self isValidIPAddress:[textField stringValue]]];
	}
	
	// Prevent spaces in the nickname field
	else if (textField == nicknameTextField)
	{
		[textField setStringValue:[[textField stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""]];
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	NSTextField* textField = (NSTextField *)[notification object];
	Window *window = (Window *) [[NSApplication sharedApplication] mainWindow];
	
	if ((textField == feedbackIpAddressTextField || textField == ipAddressTextField) && ![self isValidIPAddress:[textField stringValue]])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Invalid IP Adress"];
		[alert setInformativeText:@"Please enter a valid IPv4 Address"];
		[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:nil];
		return;
	}
	
	if (textField == feedbackIpAddressTextField || textField == feedbackPortTextField)
	{
		AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
		if ([[feedbackIpAddressTextField stringValue] isEqualToString:@"127.0.0.1"] && [feedbackPortTextField intValue] == [[appDel inPort] port])
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Invalid Feedback Address"];
			[alert setInformativeText:@"Can't send feedback to localhost on the same port atemOSC is listening on"];
			[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:nil];
			[feedbackPortTextField setIntValue:switcher.feedbackPort];
			[feedbackIpAddressTextField setStringValue:switcher.feedbackIpAddress];
			return;
		}
	}
	
	if (textField == feedbackIpAddressTextField)
	{
		[switcher setFeedbackIpAddress: [textField stringValue]];
		[switcher updateFeedback];
	}
	
	else if (textField == ipAddressTextField)
	{
		[switcher setIpAddress: [textField stringValue]];
		if ([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
			[switcher connectBMD];
	}
	
	else if (textField == feedbackPortTextField)
	{
		[switcher setFeedbackPort: [textField intValue]];
		[switcher updateFeedback];
	}
	
	else if (textField == nicknameTextField)
	{
		AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
		for (Switcher *s : [appDel switchers])
		{
			if (s.nickname != nil && [textField stringValue].length > 0 && [s.nickname isEqualToString: [textField stringValue]])
			{
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:@"Duplicate Nickname"];
				[alert setInformativeText:@"Please assign a unique nickname to each switcher"];
				[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:nil];
				[textField setStringValue:switcher.nickname];
				return;
			}
		}
		[switcher setNickname: [textField stringValue]];
		[[window addressesView] loadFromSwitcher:[self switcher]];
	}
	
	[switcher saveChanges];
	[[window outlineView] refreshList];
}

@end
