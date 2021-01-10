//
//  SwitcherCell.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import <Cocoa/Cocoa.h>
#import "Switcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwitcherCell : NSTableCellView {
	Switcher *switcher;
}
@property (assign) IBOutlet NSTextField *ipAddressNicknameTextField;
@property (assign) IBOutlet NSTextField *productNameTextField;
@property (assign) IBOutlet NSTextField *connectionStatusTextField;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSView *connectionIndicator;

- (IBAction)deleteButtonClicked:(id)sender;

- (void) updateFromSwitcher:(Switcher*)switcher;

@end

NS_ASSUME_NONNULL_END
