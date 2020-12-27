//
//  OutlineView.m
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import "OutlineView.h"
#import "AppDelegate.h"
#import "SwitcherCell.h"

@implementation OutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setDelegate: self];
		[self setDataSource: self];
		[self expandItem:nil expandChildren:YES];
		NSIndexSet* indexes = [[NSIndexSet alloc] initWithIndex:1];
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
	return self;
}

- (NSArray *) sectionHeaders
{
	return [NSArray arrayWithObject:@"Switchers"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [[self sectionHeaders] indexOfObject:item] != NSNotFound)
		return YES;
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [[self sectionHeaders] indexOfObject:item] != NSNotFound)
		return YES;
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	if (item == nil) { //item is nil when the outline view wants to inquire for root level items
		return [[self sectionHeaders] count];
	}
	
	if ([item isKindOfClass:[NSString class]] && [[self sectionHeaders] indexOfObject:item] != NSNotFound)
	{
		return [[appDel switchers] count] + 1;
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	if (item == nil) //item is nil when the outline view wants to inquire for root level items
		return [[self sectionHeaders] objectAtIndex:index];
	
	if ([item isKindOfClass:[NSString class]] && [(NSString *)item isEqualToString:@"Switchers"])
	{
		if (index < [[appDel switchers] count])
			return [[appDel switchers] objectAtIndex:index];
		return @"Add Switcher";
	}
	
	return nil;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([item isKindOfClass:[NSString class]])
		return 17;
	else if ([item isKindOfClass:[Switcher class]])
	{
		if ([item isConnected])
			return 60;
		return 45;
	}
	return 0;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [[self sectionHeaders] indexOfObject:item] != NSNotFound)
	{
		NSTableCellView *headerCell = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		[[headerCell textField] setStringValue: item];
		return headerCell;
	}
	else if ([item isKindOfClass:[NSString class]] && [item containsString:@"Add"])
	{
		NSTableCellView *addCell = [outlineView makeViewWithIdentifier:@"AddCell" owner:self];
		[[addCell textField] setStringValue: item];
		return addCell;
	}
	else if ([item isKindOfClass:[Switcher class]])
	{
		SwitcherCell *cell = [outlineView makeViewWithIdentifier:@"SwitcherCell" owner:self];
		if ([item ipAddress] && [item nickname])
			[[cell ipAddressNicknameTextField] setStringValue:[NSString stringWithFormat: @"%@ (%@)", [item ipAddress], [item nickname]]];
		else if ([item ipAddress])
			[[cell ipAddressNicknameTextField] setStringValue:[item ipAddress]];
		else
			[[cell ipAddressNicknameTextField] setStringValue:@"New Switcher"];
		
		[[cell productNameHeightConstraint] setActive:YES];
		if ([item connecting])
		{
			[[cell connectionStatusTextField] setStringValue:@"Connecting"];
			[[cell progressIndicator] startAnimation:self];
		}
		else
		{
			[[cell progressIndicator] stopAnimation:self];
			if ([item isConnected])
			{
				[[cell productNameHeightConstraint] setActive:NO];
				[[cell productNameTextField] setHidden:NO];
				[[cell connectionStatusTextField] setStringValue:@"Connected"];
			}
			else
				[[cell connectionStatusTextField] setStringValue:@"Not Connected"];
		}

		return cell;
	}
	return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
	Window *window = (Window *) [[NSApplication sharedApplication] mainWindow];

	OutlineView* outlineView = (OutlineView*) notification.object;
	id item = [outlineView itemAtRow: [outlineView selectedRow]];
	if ([item isKindOfClass:[NSString class]] && [(NSString *)item isEqualToString:@"Add Switcher"])
	{
		[[appDel switchers] addObject:[[Switcher alloc] init]];
		[outlineView reloadData];
		NSIndexSet* indexes = [[NSIndexSet alloc] initWithIndex:[[appDel switchers] count]];
		[outlineView selectRowIndexes:indexes byExtendingSelection:NO];
	} else if ([item isKindOfClass:[Switcher class]])
	{
		[[window connectionView] loadFromSwitcher:item];
		if ([item isConnected])
			[[window addressesView] loadFromSwitcher:item];
	}
}


@end
