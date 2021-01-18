#ifndef OSCReveiver_h
#define OSCReveiver_h

#import "VVOSC/VVOSC.h"
#import "OSCEndpoint.h"
#import "Switcher.h"

@class AppDelegate;

@interface OSCReceiver : NSObject <OSCDelegateProtocol>
{
	AppDelegate *appDel;
}

@property(nonatomic, retain) NSMutableDictionary *endpointMap;
@property(nonatomic, retain) NSMutableDictionary<NSString *, bool (^)(Switcher *s, NSDictionary *, OSCValue *)> *validators;

- (instancetype) initWithDelegate:(AppDelegate *)delegate;
- (void) receivedOSCMessage:(OSCMessage *)m;

@end



#endif /* OSCReveiver_h */
