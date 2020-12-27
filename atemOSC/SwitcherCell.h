//
//  SwitcherCell.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwitcherCell : NSTableCellView
@property (assign) IBOutlet NSTextField *ipAddressNicknameTextField;
@property (assign) IBOutlet NSTextField *productNameTextField;
@property (assign) IBOutlet NSTextField *connectionStatusTextField;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSLayoutConstraint *productNameHeightConstraint;
- (IBAction)deleteButtonClicked:(id)sender;

@end

NS_ASSUME_NONNULL_END
