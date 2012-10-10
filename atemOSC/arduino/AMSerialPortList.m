//
//  AMSerialPortList.m
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-09 Andreas Mayer
//  - reuse AMSerialPort objects when calling init on an existing AMSerialPortList
//  2002-09-30 Andreas Mayer
//  - added +sharedPortList
//  2004-07-05 Andreas Mayer
//  - added some log statements
//  2007-05-22 Nick Zitzmann
//  - added notifications for when serial ports are added/removed
//  2007-07-18 Sean McBride
//  - minor improvements to the added/removed notification support
//  - changed singleton creation technique, now matches Apple's sample code
//  - removed oldPortList as it is no longer needed
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean


#import "AMSDKCompatibility.h"

#import "AMSerialPortList.h"
#import "AMSerialPort.h"
#import "AMStandardEnumerator.h"

#include <termios.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>

static AMSerialPortList *AMSerialPortListSingleton = nil;

NSString *const AMSerialPortListDidAddPortsNotification = @"AMSerialPortListDidAddPortsNotification";
NSString *const AMSerialPortListDidRemovePortsNotification = @"AMSerialPortListDidRemovePortsNotification";
NSString *const AMSerialPortListAddedPorts = @"AMSerialPortListAddedPorts";
NSString *const AMSerialPortListRemovedPorts = @"AMSerialPortListRemovedPorts";


// Private prototypes
void AMSerialPortWasAddedNotification(void *refcon, io_iterator_t iterator);
void AMSerialPortWasRemovedNotification(void *refcon, io_iterator_t iterator);



@implementation AMSerialPortList

+ (AMSerialPortList *)sharedPortList
{
    @synchronized(self) {
        if (AMSerialPortListSingleton == nil) {
#ifndef __OBJC_GC__
			[[self alloc] init]; // assignment not done here
#else
			// Singleton creation is easy in the GC case, just create it if it hasn't been created yet,
			// it won't get collected since globals are strongly referenced.
			AMSerialPortListSingleton = [[self alloc] init]; 
#endif
       }
    }
    return AMSerialPortListSingleton;
}

#ifndef __OBJC_GC__

+ (id)allocWithZone:(NSZone *)zone
{
	id result = nil;
    @synchronized(self) {
        if (AMSerialPortListSingleton == nil) {
            AMSerialPortListSingleton = [super allocWithZone:zone];
			result = AMSerialPortListSingleton;  // assignment and return on first allocation
			//on subsequent allocation attempts return nil
        }
    }
	return result;
}
 
- (id)copyWithZone:(NSZone *)zone
{
	(void)zone;
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}
 
- (oneway void)release
{
    //do nothing
}
 
- (id)autorelease
{
    return self;
}

- (void)dealloc
{
	[portList release];
	[super dealloc];
}

#endif

+ (NSEnumerator *)portEnumerator
{
	return [[[AMStandardEnumerator alloc] initWithCollection:[AMSerialPortList sharedPortList]
		countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}

+ (NSEnumerator *)portEnumeratorForSerialPortsOfType:(NSString *)serialTypeKey
{
	return [[[AMStandardEnumerator alloc] initWithCollection:[[AMSerialPortList sharedPortList]
		serialPortsOfType:serialTypeKey] countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}

- (AMSerialPort *)portByPath:(NSString *)bsdPath
{
	AMSerialPort *result = nil;
	AMSerialPort *port;
	NSEnumerator *enumerator;
	
	enumerator = [portList objectEnumerator];
	while ((port = [enumerator nextObject]) != nil) {
		if ([[port bsdPath] isEqualToString:bsdPath]) {
			result = port;
			break;
		}
	}
	return result;
}

- (AMSerialPort *)getNextSerialPort:(io_iterator_t)serialPortIterator
{
	AMSerialPort	*serialPort = nil;

	io_object_t serialService = IOIteratorNext(serialPortIterator);
	if (serialService != 0) {
		CFStringRef modemName = (CFStringRef)IORegistryEntryCreateCFProperty(serialService, CFSTR(kIOTTYDeviceKey), kCFAllocatorDefault, 0);
		CFStringRef bsdPath = (CFStringRef)IORegistryEntryCreateCFProperty(serialService, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0);
		CFStringRef serviceType = (CFStringRef)IORegistryEntryCreateCFProperty(serialService, CFSTR(kIOSerialBSDTypeKey), kCFAllocatorDefault, 0);
		if (modemName && bsdPath) {
			// If the port already exists in the list of ports, we want that one.  We only create a new one as a last resort.
			serialPort = [self portByPath:(NSString*)bsdPath];
			if (serialPort == nil) {
				serialPort = [[[AMSerialPort alloc] init:(NSString*)bsdPath withName:(NSString*)modemName type:(NSString*)serviceType] autorelease];
			}
		}
		CFRelease(modemName);
		CFRelease(bsdPath);
		CFRelease(serviceType);
		
		// We have sucked this service dry of information so release it now.
		(void)IOObjectRelease(serialService);
	}
	
	return serialPort;
}

- (void)portsWereAdded:(io_iterator_t)iterator
{
	AMSerialPort *serialPort;
	NSMutableArray *addedPorts = [NSMutableArray array];
	
	while ((serialPort = [self getNextSerialPort:iterator]) != nil) {
		[portList addObject:serialPort];
		[addedPorts addObject:serialPort];
	}
	
	NSNotificationCenter* notifCenter = [NSNotificationCenter defaultCenter];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:addedPorts forKey:AMSerialPortListAddedPorts];
	[notifCenter postNotificationName:AMSerialPortListDidAddPortsNotification object:self userInfo:userInfo];
}

- (void)portsWereRemoved:(io_iterator_t)iterator
{
	AMSerialPort *serialPort;
	NSMutableArray *removedPorts = [NSMutableArray array];
	
	while ((serialPort = [self getNextSerialPort:iterator]) != nil) {
		// Since the port was removed, one should obviously not attempt to use it anymore -- so 'close' it.
		// -close does nothing if the port was never opened.
		[serialPort close];
		
		[portList removeObject:serialPort];
		[removedPorts addObject:serialPort];
	}

	NSNotificationCenter* notifCenter = [NSNotificationCenter defaultCenter];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:removedPorts forKey:AMSerialPortListRemovedPorts];
	[notifCenter postNotificationName:AMSerialPortListDidRemovePortsNotification object:self userInfo:userInfo];
}

void AMSerialPortWasAddedNotification(void *refcon, io_iterator_t iterator)
{
	(void)refcon;
	[[AMSerialPortList sharedPortList] portsWereAdded:iterator];
}

void AMSerialPortWasRemovedNotification(void *refcon, io_iterator_t iterator)
{
	(void)refcon;
	[[AMSerialPortList sharedPortList] portsWereRemoved:iterator];
}

- (void)registerForSerialPortChangeNotifications
{
	kern_return_t kernResult; 
	io_iterator_t unused;
	CFMutableDictionaryRef classesToMatch1, classesToMatch2;

	// Serial devices are instances of class IOSerialBSDClient
	classesToMatch1 = IOServiceMatching(kIOSerialBSDServiceValue);
	if (classesToMatch1 == NULL) {
#ifdef AMSerialDebug
		NSLog(@"IOServiceMatching returned a NULL dictionary.");
#endif
	} else {
		CFDictionarySetValue(classesToMatch1, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));
		classesToMatch2 = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, classesToMatch1);
	}
	
	if (classesToMatch1 != NULL)
	{
		IONotificationPortRef notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		CFRunLoopSourceRef notificationSource = IONotificationPortGetRunLoopSource(notificationPort);
		
		CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], notificationSource, kCFRunLoopCommonModes);
		
		// Set up notifications; consumes a reference to classesToMatch1
		kernResult = IOServiceAddMatchingNotification(notificationPort, kIOPublishNotification, classesToMatch1, AMSerialPortWasAddedNotification, NULL, &unused);
		if (kernResult != KERN_SUCCESS) {
#ifdef AMSerialDebug
			NSLog(@"Error %d when setting up add notifications!", kernResult);
#endif
		} else {
			while (IOIteratorNext(unused)) {}	// arm the notification
		}
		// consumes a reference to classesToMatch2
		kernResult = IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, classesToMatch2, AMSerialPortWasRemovedNotification, NULL, &unused);
		if (kernResult != KERN_SUCCESS) {
#ifdef AMSerialDebug
			NSLog(@"Error %d when setting up add notifications!", kernResult);
#endif
		} else {
			while (IOIteratorNext(unused)) {}	// arm the notification
		}
	}
}

- (void)addAllSerialPortsToArray:(NSMutableArray *)array
{
	kern_return_t kernResult; 
	CFMutableDictionaryRef classesToMatch;
	io_iterator_t serialPortIterator;
	AMSerialPort* serialPort;
	
	// Serial devices are instances of class IOSerialBSDClient
	classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
	if (classesToMatch != NULL) {
		CFDictionarySetValue(classesToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));

		// This function decrements the refcount of the dictionary passed it
		kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &serialPortIterator);    
		if (kernResult == KERN_SUCCESS) {			
			while ((serialPort = [self getNextSerialPort:serialPortIterator]) != nil) {
				[array addObject:serialPort];
			}
			(void)IOObjectRelease(serialPortIterator);
		} else {
#ifdef AMSerialDebug
			NSLog(@"IOServiceGetMatchingServices returned %d", kernResult);
#endif
		}
	} else {
#ifdef AMSerialDebug
		NSLog(@"IOServiceMatching returned a NULL dictionary.");
#endif
	}
}

- (id)init
{
	if ((self = [super init])) {
		portList = [[NSMutableArray array] retain];
	
		[self addAllSerialPortsToArray:portList];
		[self registerForSerialPortChangeNotifications];
	}
	
	return self;
}

- (NSUInteger)count
{
	return [portList count];
}

- (AMSerialPort *)objectAtIndex:(NSUInteger)idx
{
	return [portList objectAtIndex:idx];
}

- (AMSerialPort *)objectWithName:(NSString *)name
{
	AMSerialPort *result = nil;
	NSEnumerator *enumerator = [portList objectEnumerator];
	AMSerialPort *port;
	while ((port = [enumerator nextObject]) != nil) {
		if ([[port name] isEqualToString:name]) {
			result = port;
			break;
		}
	}
	return result;
}

- (NSArray *)serialPorts
{
	return [[portList copy] autorelease];
}

- (NSArray *)serialPortsOfType:(NSString *)serialTypeKey
{
	NSMutableArray *result = [NSMutableArray array];
	NSEnumerator *enumerator = [portList objectEnumerator];
	AMSerialPort *port;
	while ((port = [enumerator nextObject]) != nil) {
		if ([[port type] isEqualToString:serialTypeKey]) {
			[result addObject:port];
		}
	}
	return result;
}


@end
