//
//  OSCAddressPanel.h
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import <Cocoa/Cocoa.h>
#import "Switcher.h"

@interface OSCAddressView : NSView {
	Switcher *switcher;
}

@property (assign) IBOutlet NSTextView *helpTextView;

- (void)loadFromSwitcher:(Switcher *)switcher;

@end
