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

extern bool isMacroValid(uint32_t index);
extern bool runMacroAtIndex(uint32_t index);
extern bool stopRunningMacro();
extern uint32_t getMaxNumberOfMacros();
extern NSString* getNameOfMacro(uint32_t index);
extern NSString* getDescriptionOfMacro(uint32_t index);
extern void activateChannel(int channel, bool program);
extern bool stringIsNumber(NSString * str);
extern NSArray *mapObjectsUsingBlock(NSArray *array, id (^block)(id obj, NSUInteger idx));

#endif /* Utilities_hpp */
