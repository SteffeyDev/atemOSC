//
//  Switcher.m
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import "SwitcherCell.h"
#import "Window.h"
#import "AppDelegate.h"

@implementation SwitcherCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	[[[self connectionIndicator] layer] setCornerRadius:2];
	if ([switcher isConnected])
		[[[self connectionIndicator] layer] setBackgroundColor:[NSColor systemGreenColor].CGColor];
	else
		[[[self connectionIndicator] layer] setBackgroundColor:[NSColor systemRedColor].CGColor];}

- (IBAction)deleteButtonClicked:(id)sender
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];	
	[appDel removeSwitcher:switcher];
}

- (void) updateFromSwitcher:(Switcher*)switcher
{
	self->switcher = switcher;
	if ([switcher ipAddress] && [switcher nickname] && [[switcher nickname] length] > 0)
		[[self ipAddressNicknameTextField] setStringValue:[NSString stringWithFormat: @"%@ (%@)", [switcher ipAddress], [switcher nickname]]];
	else if ([switcher ipAddress])
		[[self ipAddressNicknameTextField] setStringValue:[switcher ipAddress]];
	else
		[[self ipAddressNicknameTextField] setStringValue:@"New Switcher"];
	
		
	if ([switcher connectionStatus] != nil)
	{
		[[self connectionStatusTextField] setStringValue:[switcher connectionStatus]];
		if ([[switcher connectionStatus] isEqualToString:@"Connecting"])
		{
			[[self progressIndicator] startAnimation:self];
		}
		else
		{
			[[self progressIndicator] stopAnimation:self];
			if ([switcher isConnected])
			{
				if ([switcher productName])
					[[self productNameTextField] setStringValue:[switcher productName]];
			}
		}
	}
	else
	{
		[[self connectionStatusTextField] setStringValue:@""];
		[[self progressIndicator] stopAnimation:self];
	}
}

@end
