//
//  Window.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/25/20.
//

#import <Cocoa/Cocoa.h>
#import "ConnectionView.h"
#import "OSCAddressView.h"
#import "OutlineView.h"
#import "LogView.h"

NS_ASSUME_NONNULL_BEGIN

@interface Window : NSWindow<NSTextFieldDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource>
@property (assign) IBOutlet OutlineView *outlineView;
@property (assign) IBOutlet NSTextField *incomingPortTextView;
@property (assign) IBOutlet ConnectionView *connectionView;
@property (assign) IBOutlet OSCAddressView *addressesView;
@property (assign) IBOutlet LogView *logView;


- (void)loadSettingsFromPreferences;

@end

NS_ASSUME_NONNULL_END
