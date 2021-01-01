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

- (void)refreshList
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	for (Switcher *switcher : [appDel switchers])
	{
		[self reloadItem:switcher];
	}
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
		[cell updateFromSwitcher:item];
		return cell;
	}
	return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	selectedRow = (long)[self selectedRow];
	
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
	Window *window = (Window *) [[NSApplication sharedApplication] mainWindow];

	id item = [self itemAtRow: selectedRow];
	if ([item isKindOfClass:[NSString class]] && [(NSString *)item isEqualToString:@"Add Switcher"])
	{
		[appDel addSwitcher];
	} else if ([item isKindOfClass:[Switcher class]])
	{
		[[window connectionView] loadFromSwitcher:item];
		if ([item isConnected])
			[[window addressesView] loadFromSwitcher:item];
	}
}


@end
