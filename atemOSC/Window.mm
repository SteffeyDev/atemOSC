//
//  Window.m
//  AtemOSC
//
//  Created by Peter Steffey on 12/25/20.
//

#import "Window.h"
#import "AppDelegate.h"

@interface Window ()

@end

@implementation Window

@synthesize outlineView;
@synthesize connectionView;
@synthesize addressesView;

- (void)loadSettingsFromPreferences
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

	NSInteger port = [prefs integerForKey:@"incoming"];
	if (port)
		[_incomingPortTextView setIntegerValue:port];
	else
		[_incomingPortTextView setIntValue:3333];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSTextField* textField = (NSTextField *)[aNotification object];
	
	if (textField == _incomingPortTextView)
	{
		int newPort = [textField intValue];
		[appDel incomingPortChanged:newPort];
		[prefs setInteger:newPort forKey:@"incoming"];
	}

	[prefs synchronize];
}

@end
