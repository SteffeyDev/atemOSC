//
//  LogView.m
//  AtemOSC
//
//  Created by Peter Steffey on 1/1/21.
//

#import "LogView.h"
#import "AppDelegate.h"

@implementation LogView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder])
	{
		[self setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
		[self setMaterial:NSVisualEffectMaterialDark];
		[self setState:NSVisualEffectStateActive];
		self->fullLog = [[NSMutableString alloc] init];
		self->basicLog = [[NSMutableString alloc] init];
		self->debugMode = false;
		return self;
	}
	return nil;
}

- (void)logMessage:(NSString *)message
{
	if (message) {
		NSLog(@"%@", message);
		
		NSDate *now = [NSDate date];
		NSDateFormatter *formatter = nil;
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"HH:mm:ss"];
		
		NSString *messageWithNewLine = [NSString stringWithFormat:@"[%@] %@\n", [formatter stringFromDate:now], message];
		NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc]initWithString:messageWithNewLine];

		[fullLog appendString:messageWithNewLine];
		if (![message containsString:@"[Debug]"])
			[basicLog appendString:messageWithNewLine];

		if (![message containsString:@"[Debug]"] || debugMode)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				NSColor *color = [[self logTextView] textColor];
				[[self logTextView].textStorage appendAttributedString:attributedMessage];
				[[self logTextView] scrollRangeToVisible: NSMakeRange([self logTextView].string.length, 0)];
				
				// Need to set color to original color, because adding attributed string resets the text color to black for some reason
				[[self logTextView] setTextColor:color];
			});
		}
	}
}

- (void)flushMessages
{
	NSColor *color = [[self logTextView] textColor];
	if ([[self debugCheckbox] state])
	{
		[[[self logTextView] textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:fullLog]];
	}
	else
	{
		[[[self logTextView] textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:basicLog]];
	}
	[[self logTextView] scrollRangeToVisible: NSMakeRange([self logTextView].string.length, 0)];
	[[self logTextView] setTextColor:color];
}

- (IBAction)debugChanged:(id)sender {
	self->debugMode = [[self debugCheckbox] state];
	[self flushMessages];
}

@end
