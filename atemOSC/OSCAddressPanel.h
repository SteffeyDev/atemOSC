//
//  OSCAddressPanel.h
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import <Cocoa/Cocoa.h>

@class AppDelegate;

@interface OSCAddressPanel : NSPanel {
	IBOutlet NSTextView*        helpTextView;
}

- (void)setupWithDelegate:(AppDelegate *)appDel;

@end
