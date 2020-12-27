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
@synthesize logTextView;

- (void)loadSettingsFromPreferences
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

	if ([prefs integerForKey:@"incoming"])
		[_incomingPortTextView setIntegerValue:[prefs integerForKey:@"incoming"]];
	else
		[_incomingPortTextView setIntValue:3333];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSTextField* textField = (NSTextField *)[aNotification object];
	
	int newPort = [textField intValue];
	[appDel incomingPortChanged:newPort];
	[_incomingPortTextView setIntValue:newPort];
	
	if (textField == _incomingPortTextView)
		[prefs setInteger:newPort forKey:@"incoming"];

	[prefs synchronize];
}

- (void) refreshList
{
	[outlineView reloadData];
}


@end
