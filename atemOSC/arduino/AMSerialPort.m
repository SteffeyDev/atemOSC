//
//  AMSerialPort.m
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-09-18 Andreas Mayer
//  - added available & owner
//  2002-10-10 Andreas Mayer
//	- some log messages changed
//  2002-10-25 Andreas Mayer
//	- additional locks and other changes for reading and writing in background
//  2003-11-26 James Watson
//	- in dealloc [self close] reordered to execute before releasing closeLock
//  2007-05-22 Nick Zitzmann
//  - added -hash and -isEqual: methods
//  2007-07-18 Sean McBride
//  - behaviour change: -open and -close must now always be matched, -dealloc checks this
//  - added -debugDescription so gdb's 'po' command gives something useful
//  2007-07-25 Andreas Mayer
// - replaced -debugDescription by -description; works for both, gdb's 'po' and NSLog()
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean
//	2009-3-20 Pat O'Keefe
//	- fixed setSpeed method


#import "AMSDKCompatibility.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sys/time.h>
#include <sysexits.h>
#include <sys/param.h>
#include <sys/ioctl.h>

#import "AMSerialPort.h"
#import "AMSerialErrors.h"

#import <IOKit/serial/IOSerialKeys.h>
#if defined(MAC_OS_X_VERSION_10_4) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4)
	#import <IOKit/serial/ioss.h>
#endif

NSString *const AMSerialErrorDomain = @"de.harmless.AMSerial.ErrorDomain";


@implementation AMSerialPort

- (id)init:(NSString *)path withName:(NSString *)name type:(NSString *)type
	// path is a bsdPath
	// name is an IOKit service name
{
	if ((self = [super init])) {
		bsdPath = [path copy];
		serviceName = [name copy];
		serviceType = [type copy];
		optionsDictionary = [[NSMutableDictionary dictionaryWithCapacity:8] retain];
#ifndef __OBJC_GC__
		options = (struct termios*)malloc(sizeof(*options));
		originalOptions = (struct termios*)malloc(sizeof(*originalOptions));
		buffer = (char*)malloc(AMSER_MAXBUFSIZE);
		readfds = (fd_set*)malloc(sizeof(*readfds));
#else
		options = (struct termios*)NSAllocateCollectable(sizeof(*options), 0);
		originalOptions = (struct termios*)NSAllocateCollectable(sizeof(*originalOptions), 0);
		buffer = (char*)NSAllocateCollectable(AMSER_MAXBUFSIZE, 0);
		readfds = (fd_set*)NSAllocateCollectable(sizeof(*readfds), 0);
#endif
		fileDescriptor = -1;
		
		writeLock = [[NSLock alloc] init];
		readLock = [[NSLock alloc] init];
		closeLock = [[NSLock alloc] init];
		
		// By default blocking read attempts will timeout after 1 second
		[self setReadTimeout:1.0];
	}
	return self;
}

#ifndef __OBJC_GC__

- (void)dealloc
{
#ifdef AMSerialDebug
	if (fileDescriptor != -1)
		NSLog(@"It is a programmer error to have not called -close on an AMSerialPort you have opened");
#endif
	
	[readLock release];
	[writeLock release];
	[closeLock release];
	[am_readTarget release];
	
	free(readfds);
	free(buffer);
	free(originalOptions);
	free(options);
	[optionsDictionary release];
	[serviceName release];
	[serviceType release];
	[bsdPath release];
	[super dealloc];
}

#else

- (void)finalize
{
#ifdef AMSerialDebug
	if (fileDescriptor != -1)
		NSLog(@"It is a programmer error to have not called -close on an AMSerialPort you have opened");
#endif
	assert (fileDescriptor == -1);

	[super finalize];
}

#endif

// So NSLog and gdb's 'po' command give something useful
- (NSString *)description
{
	NSString *result= [NSString stringWithFormat:@"<%@: %x = name: %@, path: %@, type: %@, fileHandle: %@, fileDescriptor: %d>", NSStringFromClass([self class]), (long unsigned)self, serviceName, bsdPath, serviceType, fileHandle, fileDescriptor];
	return result;
}

- (NSUInteger)hash
{
	return [[self bsdPath] hash];
}

- (BOOL)isEqual:(id)otherObject
{
	if ([otherObject isKindOfClass:[AMSerialPort class]])
		return [[self bsdPath] isEqualToString:[otherObject bsdPath]];
	return NO;
}


- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	id old = nil;
	
	if (newDelegate != delegate) {
		old = delegate;
		delegate = [newDelegate retain];
		[old release];
		delegateHandlesReadInBackground = [delegate respondsToSelector:@selector(serialPortReadData:)];
		delegateHandlesWriteInBackground = [delegate respondsToSelector:@selector(serialPortWriteProgress:)];
	}
}


- (NSString *)bsdPath
{
	return bsdPath;
}

- (NSString *)name
{
	return serviceName;
}

- (NSString *)type
{
	return serviceType;
}

- (NSDictionary *)properties
{
	NSDictionary *result = nil;
	kern_return_t kernResult; 
	CFMutableDictionaryRef matchingDictionary;
	io_service_t serialService;
	
	matchingDictionary = IOServiceMatching(kIOSerialBSDServiceValue);
	CFDictionarySetValue(matchingDictionary, CFSTR(kIOTTYDeviceKey), (CFStringRef)[self name]);
	if (matchingDictionary != NULL) {
		CFRetain(matchingDictionary);
		// This function decrements the refcount of the dictionary passed it
		serialService = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDictionary);
		
		if (serialService) {
			NSMutableDictionary *propertiesDict;
			kernResult = IORegistryEntryCreateCFProperties(serialService, (CFMutableDictionaryRef *)&propertiesDict, kCFAllocatorDefault, 0);
			if (kernResult == KERN_SUCCESS) {
				result = [propertiesDict autorelease];
			}
		} else {
#ifdef AMSerialDebug
			NSLog(@"properties: no matching service for %@", matchingDictionary);
#endif
		}
		CFRelease(matchingDictionary);
		// We have sucked this service dry of information so release it now.
		(void)IOObjectRelease(serialService);
	}
	return result;
}


- (BOOL)isOpen
{
	// YES if port is open
	return (fileDescriptor >= 0);
}

- (AMSerialPort *)obtainBy:(id)sender
{
	// get this port exclusively; NULL if it's not free
	if (owner == nil) {
		owner = sender;
		return self;
	} else
		return nil;
}

- (void)free
{
	// give it back
	owner = nil;
	[self close];	// you never know ...
}

- (BOOL)available
{
	// check if port is free and can be obtained
	return (owner == nil);
}

- (id)owner
{
	// who obtained the port?
	return owner;
}


- (NSFileHandle *)open // use returned file handle to read and write
{
	NSFileHandle *result = nil;
	
	const char *path = [bsdPath fileSystemRepresentation];
	fileDescriptor = open(path, O_RDWR | O_NOCTTY); // | O_NONBLOCK);

#ifdef AMSerialDebug
	NSLog(@"open %@ (%d)\n", bsdPath, fileDescriptor);
#endif
	
	if (fileDescriptor < 0)	{
#ifdef AMSerialDebug
		NSLog(@"Error opening serial port %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
#endif
	} else {
		/*
		 if (fcntl(fileDescriptor, F_SETFL, fcntl(fileDescriptor, F_GETFL, 0) & !O_NONBLOCK) == -1)
		 {
			 NSLog(@"Error clearing O_NDELAY %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
		 } // ... else
		 */
		// get the current options and save them for later reset
		if (tcgetattr(fileDescriptor, originalOptions) == -1) {
#ifdef AMSerialDebug
			NSLog(@"Error getting tty attributes %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
#endif
		} else {
			// Make an exact copy of the options
			*options = *originalOptions;
			
			// This object owns the fileDescriptor and must dispose it later
			// In other words, you must balance calls to -open with -close
			fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor];
			result = fileHandle;
		}
	}
	if (!result) { // failure
		if (fileDescriptor >= 0) {
			close(fileDescriptor);
		}
		fileDescriptor = -1;
	}
	return result;
}


- (void)close
{
	// Traditionally it is good to reset a serial port back to
	// the state in which you found it.  Let's continue that tradition.
	if (fileDescriptor >= 0) {
		//NSLog(@"close - attempt closeLock");
		[closeLock lock];
		//NSLog(@"close - closeLock locked");
		
		// kill pending read by setting O_NONBLOCK
		if (fcntl(fileDescriptor, F_SETFL, fcntl(fileDescriptor, F_GETFL, 0) | O_NONBLOCK) == -1) {
#ifdef AMSerialDebug
			NSLog(@"Error clearing O_NONBLOCK %@ - %s(%d).\n", bsdPath, strerror(errno), errno);
#endif
		}
		if (tcsetattr(fileDescriptor, TCSANOW, originalOptions) == -1) {
#ifdef AMSerialDebug
			NSLog(@"Error resetting tty attributes - %s(%d).\n", strerror(errno), errno);
#endif
		}
		
		// Disallows further access to the communications channel
		[fileHandle closeFile];

		// Release the fileHandle
		[fileHandle release];
		fileHandle = nil;
		
#ifdef AMSerialDebug
		NSLog(@"close (%d)\n", fileDescriptor);
#endif
		// Close the fileDescriptor, that is our responsibility since the fileHandle does not own it
		close(fileDescriptor);
		fileDescriptor = -1;
		
		[closeLock unlock];
		//NSLog(@"close - closeLock unlocked");
	}
}

- (BOOL)drainInput
{
	BOOL result = (tcdrain(fileDescriptor) != -1);
	return result;
}

- (BOOL)flushInput:(BOOL)fIn Output:(BOOL)fOut	// (fIn or fOut) must be YES
{
	int mode = 0;
	if (fIn == YES)
		mode = TCIFLUSH;
	if (fOut == YES)
		mode = TCOFLUSH;
	if (fIn && fOut)
		mode = TCIOFLUSH;
	
	BOOL result = (tcflush(fileDescriptor, mode) != -1);
	return result;
}

- (BOOL)sendBreak
{
	BOOL result = (tcsendbreak(fileDescriptor, 0) != -1);
	return result;
}

- (BOOL)setDTR
{
	BOOL result = (ioctl(fileDescriptor, TIOCSDTR) != -1);
	return result;
}

- (BOOL)clearDTR
{
	BOOL result = (ioctl(fileDescriptor, TIOCCDTR) != -1);
	return result;
}


// read and write serial port settings through a dictionary

- (void)buildOptionsDictionary
{
	[optionsDictionary removeAllObjects];
	[optionsDictionary setObject:[self name] forKey:AMSerialOptionServiceName];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self speed]] forKey:AMSerialOptionSpeed];
	[optionsDictionary setObject:[NSString stringWithFormat:@"%ul", [self dataBits]] forKey:AMSerialOptionDataBits];
	switch ([self parity]) {
		case kAMSerialParityOdd: {
			[optionsDictionary setObject:@"Odd" forKey:AMSerialOptionParity];
			break;
		}
		case kAMSerialParityEven: {
			[optionsDictionary setObject:@"Even" forKey:AMSerialOptionParity];
			break;
		}
		default:;
	}
	
	[optionsDictionary setObject:[NSString stringWithFormat:@"%d", [self stopBits]] forKey:AMSerialOptionStopBits];
	if ([self RTSInputFlowControl])
		[optionsDictionary setObject:@"RTS" forKey:AMSerialOptionInputFlowControl];
	if ([self DTRInputFlowControl])
		[optionsDictionary setObject:@"DTR" forKey:AMSerialOptionInputFlowControl];
	
	if ([self CTSOutputFlowControl])
		[optionsDictionary setObject:@"CTS" forKey:AMSerialOptionOutputFlowControl];
	if ([self DSROutputFlowControl])
		[optionsDictionary setObject:@"DSR" forKey:AMSerialOptionOutputFlowControl];
	if ([self CAROutputFlowControl])
		[optionsDictionary setObject:@"CAR" forKey:AMSerialOptionOutputFlowControl];
	
	if ([self echoEnabled])
		[optionsDictionary setObject:@"YES" forKey:AMSerialOptionEcho];

	if ([self canonicalMode])
		[optionsDictionary setObject:@"YES" forKey:AMSerialOptionCanonicalMode];

}


- (NSDictionary *)options
{
	// will open the port to get options if neccessary
	if ([optionsDictionary objectForKey:AMSerialOptionServiceName] == nil) {
		if (fileDescriptor < 0) {
			[self open];
			[self close];
		}
		[self buildOptionsDictionary];
	}
	return [NSMutableDictionary dictionaryWithDictionary:optionsDictionary];
}

- (void)setOptions:(NSDictionary *)newOptions
{
	// AMSerialOptionServiceName HAS to match! You may NOT switch ports using this
	// method.
	NSString *temp;
	
	if ([(NSString *)[newOptions objectForKey:AMSerialOptionServiceName] isEqualToString:[self name]]) {
		[self clearError];
		[optionsDictionary addEntriesFromDictionary:newOptions];
		// parse dictionary
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionSpeed];
		[self setSpeed:[temp intValue]];
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionDataBits];
		[self setDataBits:[temp intValue]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionParity];
		if (temp == nil)
			[self setParity:kAMSerialParityNone];
		else if ([temp isEqualToString:@"Odd"])
			[self setParity:kAMSerialParityOdd];
		else
			[self setParity:kAMSerialParityEven];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionStopBits];
		int		numStopBits = [temp intValue];
		[self setStopBits:(AMSerialStopBits)numStopBits];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionInputFlowControl];
		[self setRTSInputFlowControl:[temp isEqualToString:@"RTS"]];
		[self setDTRInputFlowControl:[temp isEqualToString:@"DTR"]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionOutputFlowControl];
		[self setCTSOutputFlowControl:[temp isEqualToString:@"CTS"]];
		[self setDSROutputFlowControl:[temp isEqualToString:@"DSR"]];
		[self setCAROutputFlowControl:[temp isEqualToString:@"CAR"]];
		
		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionEcho];
		[self setEchoEnabled:(temp != nil)];

		temp = (NSString *)[optionsDictionary objectForKey:AMSerialOptionCanonicalMode];
		[self setCanonicalMode:(temp != nil)];

		[self commitChanges];
	} else {
#ifdef AMSerialDebug
		NSLog(@"Error setting options for port %s (wrong port name: %s).\n", [self name], [newOptions objectForKey:AMSerialOptionServiceName]);
#endif
	}
}


- (long)speed
{
	return cfgetospeed(options);	// we should support cfgetispeed too
}

- (BOOL)setSpeed:(long)speed
{
	BOOL result = YES;
	int errorCode = 0;
	
	options->c_ospeed = speed;
	options->c_ispeed = speed;
	
#if defined(MAC_OS_X_VERSION_10_4) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4)
	// Starting with Tiger, the IOSSIOSPEED ioctl can be used to set arbitrary baud rates
	// other than those specified by POSIX. The driver for the underlying serial hardware
	// ultimately determines which baud rates can be used. This ioctl sets both the input
	// and output speed. 
	
	speed_t newSpeed = speed;
	if (fileDescriptor >= 0) {
		errorCode = ioctl(fileDescriptor, IOSSIOSPEED, &newSpeed);
	} else {
		result = NO;
		gotError = YES;
		lastError = EBADF; // Bad file descriptor
	}
#else
	// set both the input and output speed
	errorCode = cfsetospeed(options, speed);
	errorCode = cfsetispeed(options, speed);
#endif
	if (errorCode == -1) {
		result = NO;
		gotError = YES;
		lastError = errno;
	}
	return result;
}


- (unsigned long)dataBits
{
	return 5 + ((options->c_cflag & CSIZE) >> 8);
	// man ... I *hate* C syntax ...
}

- (void)setDataBits:(unsigned long)bits	// 5 to 8 (5 is marked as "(pseudo)")
{
	// ?? options->c_oflag &= ~OPOST;
	options->c_cflag &= ~CSIZE;
	switch (bits) {
		case 5:	options->c_cflag |= CS5;	// redundant since CS5 == 0
			break;
		case 6:	options->c_cflag |= CS6;
			break;
		case 7:	options->c_cflag |= CS7;
			break;
		case 8:	options->c_cflag |= CS8;
			break;
	}
}


- (AMSerialParity)parity
{
	AMSerialParity result;
	if (options->c_cflag & PARENB) {
		if (options->c_cflag & PARODD) {
			result = kAMSerialParityOdd;
		} else {
			result = kAMSerialParityEven;
		}
	} else {
		result = kAMSerialParityNone;
	}
	return result;
}

- (void)setParity:(AMSerialParity)newParity
{
	switch (newParity) {
		case kAMSerialParityNone: {
			options->c_cflag &= ~PARENB;
			break;
		}
		case kAMSerialParityOdd: {
			options->c_cflag |= PARENB;
			options->c_cflag |= PARODD;
			break;
		}
		case kAMSerialParityEven: {
			options->c_cflag |= PARENB;
			options->c_cflag &= ~PARODD;
			break;
		}
	}
}


- (AMSerialStopBits)stopBits
{
	if (options->c_cflag & CSTOPB)
		return kAMSerialStopBitsTwo;
	else
		return kAMSerialStopBitsOne;
}

- (void)setStopBits:(AMSerialStopBits)numBits
{
	if (numBits == kAMSerialStopBitsOne)
		options->c_cflag &= ~CSTOPB;
	else if (numBits == kAMSerialStopBitsTwo)
		options->c_cflag |= CSTOPB;
}


- (BOOL)echoEnabled
{
	return (options->c_lflag & ECHO);
}

- (void)setEchoEnabled:(BOOL)echo
{
	if (echo == YES)
		options->c_lflag |= ECHO;
	else
		options->c_lflag &= ~ECHO;
}


- (BOOL)RTSInputFlowControl
{
	return (options->c_cflag & CRTS_IFLOW);
}

- (void)setRTSInputFlowControl:(BOOL)rts
{
	if (rts == YES)
		options->c_cflag |= CRTS_IFLOW;
	else
		options->c_cflag &= ~CRTS_IFLOW;
}


- (BOOL)DTRInputFlowControl
{
	return (options->c_cflag & CDTR_IFLOW);
}

- (void)setDTRInputFlowControl:(BOOL)dtr
{
	if (dtr == YES)
		options->c_cflag |= CDTR_IFLOW;
	else
		options->c_cflag &= ~CDTR_IFLOW;
}


- (BOOL)CTSOutputFlowControl
{
	return (options->c_cflag & CCTS_OFLOW);
}

- (void)setCTSOutputFlowControl:(BOOL)cts
{
	if (cts == YES)
		options->c_cflag |= CCTS_OFLOW;
	else
		options->c_cflag &= ~CCTS_OFLOW;
}


- (BOOL)DSROutputFlowControl
{
	return (options->c_cflag & CDSR_OFLOW);
}

- (void)setDSROutputFlowControl:(BOOL)dsr
{
	if (dsr == YES)
		options->c_cflag |= CDSR_OFLOW;
	else
		options->c_cflag &= ~CDSR_OFLOW;
}


- (BOOL)CAROutputFlowControl
{
	return (options->c_cflag & CCAR_OFLOW);
}

- (void)setCAROutputFlowControl:(BOOL)car
{
	if (car == YES)
		options->c_cflag |= CCAR_OFLOW;
	else
		options->c_cflag &= ~CCAR_OFLOW;
}


- (BOOL)hangupOnClose
{
	return (options->c_cflag & HUPCL);
}

- (void)setHangupOnClose:(BOOL)hangup
{
	if (hangup == YES)
		options->c_cflag |= HUPCL;
	else
		options->c_cflag &= ~HUPCL;
}

- (BOOL)localMode
{
	return (options->c_cflag & CLOCAL);
}

- (void)setLocalMode:(BOOL)local
{
	// YES = ignore modem status lines
	if (local == YES)
		options->c_cflag |= CLOCAL;
	else
		options->c_cflag &= ~CLOCAL;
}

- (BOOL)canonicalMode
{
	return (options->c_lflag & ICANON);
}

- (void)setCanonicalMode:(BOOL)flag
{
	if (flag == YES)
		options->c_lflag |= ICANON;
	else
		options->c_lflag &= ~ICANON;
}

- (char)endOfLineCharacter
{
	return options->c_cc[VEOL];
}

- (void)setEndOfLineCharacter:(char)eol
{
	options->c_cc[VEOL] = eol;
}

- (void)clearError
{
	// call this before changing any settings
	gotError = NO;
}

- (BOOL)commitChanges
{
	// call this after using any of the setters above
	if (gotError)
		return NO;
	
	if (tcsetattr(fileDescriptor, TCSANOW, options) == -1) {
		// something went wrong
		gotError = YES;
		lastError = errno;
		return NO;
	} else {
		[self buildOptionsDictionary];
		return YES;
	}
}

- (int)errorCode
{
	// if -commitChanges returns NO, look here for further info
	return lastError;
}

- (NSTimeInterval)readTimeout
{
    return readTimeout;
}

- (void)setReadTimeout:(NSTimeInterval)aReadTimeout
{
    readTimeout = aReadTimeout;
}

// private methods

- (void)readTimeoutAsTimeval:(struct timeval*)timeout
{
	NSTimeInterval timeoutInterval = [self readTimeout];
	double numSecs = trunc(timeoutInterval);
	double numUSecs = (timeoutInterval-numSecs)*1000000.0;
	timeout->tv_sec = (time_t)lrint(numSecs);
	timeout->tv_usec = (suseconds_t)lrint(numUSecs);
}


@end
