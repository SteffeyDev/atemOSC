//
//  OSCAddressPanel.h
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import <Cocoa/Cocoa.h>

@class AppDelegate;

@interface OSCAddressPanel : NSPanel {
    IBOutlet NSTextView*        heltTextView;
}

- (id)initWithDelegate:(AppDelegate *)delegate;

@end
