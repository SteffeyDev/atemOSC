#ifndef OSCReveiver_h
#define OSCReveiver_h

#import "VVOSC/VVOSC.h"

@class AppDelegate;

@interface OSCReceiver : NSObject <OSCDelegateProtocol>
{
	AppDelegate *appDel;
}

- (instancetype) initWithDelegate:(AppDelegate *)delegate;
- (void) receivedOSCMessage:(OSCMessage *)m;

@end

#endif /* OSCReveiver_h */
