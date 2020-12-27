//
//  ConnectionView.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import <Cocoa/Cocoa.h>
#import "Switcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionView : NSView<NSTextFieldDelegate> {
	Switcher *switcher;
}

@property (assign) IBOutlet NSTextField *ipAddressTextField;
@property (assign) IBOutlet NSTextField *nicknameTextField;
@property (assign) IBOutlet NSTextField *productNameTextField;
@property (assign) IBOutlet NSTextField *feedbackIpAddressTextField;
@property (assign) IBOutlet NSTextField *feedbackPortTextField;


- (void)loadFromSwitcher:(Switcher *)switcher;
- (void)reload;

@end

NS_ASSUME_NONNULL_END
