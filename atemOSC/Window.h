//
//  Window.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/25/20.
//

#import <Cocoa/Cocoa.h>
#import "ConnectionView.h"
#import "OSCAddressView.h"

NS_ASSUME_NONNULL_BEGIN

@interface Window : NSWindow<NSTextFieldDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource>
{
	NSArray *_sectionHeaders;
}
@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet NSTextView *logTextView;
@property (assign) IBOutlet NSTextField *incomingPortTextView;
@property (assign) IBOutlet ConnectionView *connectionView;
@property (assign) IBOutlet OSCAddressView *addressesView;

- (void)loadSettingsFromPreferences;
- (void)refreshList;

@end

NS_ASSUME_NONNULL_END
