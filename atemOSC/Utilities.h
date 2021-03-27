//
//  Utilities.hpp
//  AtemOSC
//
//  Created by Peter Steffey on 11/4/17.
//

#ifndef Utilities_hpp
#define Utilities_hpp

#include <stdio.h>
#import "BMDSwitcherAPI.h"
#import "Switcher.h"

extern bool isMacroValid(Switcher *s, uint32_t index);
extern bool runMacroAtIndex(Switcher *s, uint32_t index);
extern bool stopRunningMacro(Switcher *s);
extern uint32_t getMaxNumberOfMacros(Switcher *s);
extern NSString* getNameOfMacro(Switcher *s, uint32_t index);
extern NSString* getDescriptionOfMacro(Switcher *s, uint32_t index);
extern void activateChannel(Switcher *s, int me, int channel, bool program);
extern bool stringIsNumber(NSString * str);
extern NSArray *mapObjectsUsingBlock(NSArray *array, id (^block)(id obj, NSUInteger idx));
void sendFeedbackMessage(Switcher *s, NSString *address, OSCValue* val, bool printToLog = true);
void sendFeedbackMessage(Switcher *s, NSString *address, OSCValue* val, int me, bool printToLog = true);

#endif /* Utilities_hpp */
