//
//  AMSerialPortList.h
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-09 Andreas Mayer
//  - reuse AMSerialPort objects when calling init on an existing AMSerialPortList
//  2002-09-30 Andreas Mayer
//  - added +sharedPortList
//  2004-02-10 Andreas Mayer
//  - added +portEnumerator
//  2006-08-16 Andreas Mayer
//  - added methods dealing with ports of a certain serial type
//  - renamed -getSerialPorts to -serialPorts - moved old declaration to Deprecated category
//  2007-05-22 Nick Zitzmann
//  - added notifications for when serial ports are added/removed
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean

#import "AMSDKCompatibility.h"

#import <Foundation/Foundation.h>

// For constants clients will want to pass to methods that want a 'serialTypeKey'
#import <IOKit/serial/IOSerialKeys.h>
// note: the constants are C strings, so use '@' or CFSTR to convert, for example:
// NSArray *ports = [[AMSerialPort sharedPortList] serialPortsOfType:@kIOSerialBSDModemType];
// NSArray *ports = [[AMSerialPort sharedPortList] serialPortsOfType:(NSString*)CFSTR(kIOSerialBSDModemType)];

@class AMSerialPort;

extern NSString * const AMSerialPortListDidAddPortsNotification;
extern NSString * const AMSerialPortListDidRemovePortsNotification;
extern NSString * const AMSerialPortListAddedPorts;
extern NSString * const AMSerialPortListRemovedPorts;

@interface AMSerialPortList : NSObject
{
@private
	NSMutableArray *portList;
}

+ (AMSerialPortList *)sharedPortList;

+ (NSEnumerator *)portEnumerator;
+ (NSEnumerator *)portEnumeratorForSerialPortsOfType:(NSString *)serialTypeKey;

- (NSUInteger)count;
- (AMSerialPort *)objectAtIndex:(NSUInteger)idx;
- (AMSerialPort *)objectWithName:(NSString *)name;

- (NSArray *)serialPorts;
- (NSArray *)serialPortsOfType:(NSString *)serialTypeKey;


@end
