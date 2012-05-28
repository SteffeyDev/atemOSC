//
//  AMSerialPortList_Deprecated.m
//  AMSerialTest
//
//  Created by Andreas on 14.08.06.
//  Copyright 2006 Andreas Mayer. All rights reserved.
//

#import "AMSerialPortList_Deprecated.h"


@implementation AMSerialPortList (Deprecated)

- (NSArray *)getPortList
{
	return [self serialPorts];
}


@end
