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
		//[self setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
		//[self setMaterial:NSVisualEffectMaterialDark];
		//[self setState:NSVisualEffectStateActive];
		self->fullLog = [[NSMutableArray alloc] init];
		self->basicLog = [[NSMutableArray alloc] init];
		self->debugMode = false;
		self->live = true;
		self->formatter = [[NSDateFormatter alloc] init];
		[self->formatter setDateFormat:@"HH:mm:ss"];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userScolled) name:NSScrollViewDidLiveScrollNotification object:nil];
		
		NSTimer* timer = [NSTimer timerWithTimeInterval:0.5
												 target:self
											   selector:@selector(reloadData)
											   userInfo:nil
												repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
				
		return self;
	}
	return nil;
}

// This will be run twice a second
- (void)reloadData
{
	if (self->live)
	{
		if (self->fullLog.count > 2000)
		{
			[self->fullLog removeObjectsInRange:NSMakeRange(0, fmax(self->fullLog.count - 2100, 100))];
		}
		if (self->basicLog.count > 2000)
		{
			[self->basicLog removeObjectsInRange:NSMakeRange(0, fmax(self->basicLog.count - 2100, 100))];
		}
		[[self tableView] reloadData];
		[[self tableView] scrollToEndOfDocument:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return debugMode ? fullLog.count : basicLog.count;
}

- (NSTableCellView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cell = [tableView makeViewWithIdentifier:@"cell" owner:self];
	[cell.textField setStringValue: debugMode ? [fullLog objectAtIndex:row] : [basicLog objectAtIndex:row]];
	return cell;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

// If the user scrolls up in the log, pause live updates so that they can inspect the log
// When they scroll back to the bottom, resume live updates
- (void)userScolled
{
	BOOL scrollAtBottom = [[[[self tableView] enclosingScrollView] verticalScroller] floatValue] == 1.0;
	BOOL scrollNeeded = [[[self tableView] enclosingScrollView] documentView].bounds.size.height > [[[self tableView] enclosingScrollView] contentView].bounds.size.height;
	if (scrollAtBottom || !scrollNeeded)
	{
		if (self->live == NO)
		{
			[[self pausedLabel] setHidden:YES];
			self->live = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[self tableView] reloadData];
				[[self tableView] layout];
				[[self tableView] scrollToEndOfDocument:nil];
			});
		}
	}
	else if (self->live == YES)
	{
		[[self pausedLabel] setHidden:NO];
		self->live = NO;
	}
}

- (void)logMessage:(NSString *)message
{
	if (message) {
		NSLog(@"%@", message);
		
		NSDate *now = [NSDate date];
		NSString *messageWithTime = [NSString stringWithFormat:@"[%@] %@", [self->formatter stringFromDate:now], message];
		BOOL isDebugMessage = [message containsString:@"[Debug]"]; // calc here for performance
		
		// Keep this update small and fast, do more heavy lifting on the task run once a second
		dispatch_async(dispatch_get_main_queue(), ^{
			[self->fullLog addObject:messageWithTime];
			if (!isDebugMessage)
				[self->basicLog addObject:messageWithTime];
		});
	}
}

- (IBAction)debugChanged:(id)sender {
	self->debugMode = [[self debugCheckbox] state];
	[[self tableView] reloadData];
}

@end
