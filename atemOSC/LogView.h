//
//  LogView.h
//  AtemOSC
//
//  Created by Peter Steffey on 1/1/21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogView : NSVisualEffectView {
	NSMutableString*		basicLog; // no debug info
	NSMutableString*		fullLog; // normal and debug log
	BOOL					debugMode;
}

@property (assign) IBOutlet NSTextView *logTextView;
@property (assign) IBOutlet NSButton *debugCheckbox;

- (IBAction)debugChanged:(id)sender;


-(void)flushMessages;
- (void)logMessage:(NSString *)message toForeground:(BOOL)active;

@end

NS_ASSUME_NONNULL_END
