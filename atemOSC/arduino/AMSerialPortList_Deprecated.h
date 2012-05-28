//
//  AMSerialPortList_Deprecated.h
//  AMSerialTest
//
//  Created by Andreas on 14.08.06.
//  Copyright 2006 Andreas Mayer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMSerialPortList.h"


@interface AMSerialPortList (Deprecated)

- (NSArray *)getPortList;
// replaced by  -serialPorts;


@end
