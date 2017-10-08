//
//  OSCReceiver.h
//  atemOSC
//
//  Created by Peter Steffey on 10/7/17.
//

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

- (void) handleMacros:(OSCMessage *)m address:(NSArray*)address;
- (void) handleAuxSource:(int)auxToChange channel:(int)channel;
- (void) handleSuperSource:(OSCMessage *)m address:(NSArray*)address;
- (void) handleSuperSourceBox:(OSCMessage *)m address:(NSArray*)address;
- (void) activateChannel:(int)channel isProgram:(BOOL)program;
- (NSString*)getDescriptionOfMacro:(uint32_t)index;
- (NSString*)getNameOfMacro:(uint32_t)index;
- (uint32_t)getMaxNumberOfMacros;
- (BOOL)stopRunningMacro;
- (BOOL)runMacroAtIndex:(uint32_t)index;
- (BOOL)isMacroValid:(uint32_t)index;

@end

#endif /* OSCReveiver_h */
