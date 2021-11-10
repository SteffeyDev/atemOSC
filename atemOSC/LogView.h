//
//  LogView.h
//  AtemOSC
//
//  Created by Peter Steffey on 1/1/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogView : NSView<NSTableViewDelegate, NSTableViewDataSource> {
	NSMutableArray*		basicLog; // no debug info
	NSMutableArray*		fullLog; // normal and debug log
	BOOL				debugMode;
	BOOL				live;
	BOOL				logChanged;
	NSDateFormatter* 	formatter;
}

@property (assign) IBOutlet NSButton *debugCheckbox;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTextField *pausedLabel;


- (IBAction)debugChanged:(id)sender;

- (void)logMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
