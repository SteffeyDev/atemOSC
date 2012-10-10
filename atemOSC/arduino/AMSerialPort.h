//
//  AMSerialPort.h
//
//  Created by Andreas on 2002-04-24.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//
//
//  2002-09-18 Andreas Mayer
//  - added available & owner
//  2002-10-17 Andreas Mayer
//	- countWriteInBackgroundThreads and countWriteInBackgroundThreadsLock added
//  2002-10-25 Andreas Mayer
//	- more additional instance variables for reading and writing in background
//  2004-02-10 Andreas Mayer
//    - added delegate for background reading/writing
//  2005-04-04 Andreas Mayer
//	- added setDTR and clearDTR
//  2006-07-28 Andreas Mayer
//	- added -canonicalMode, -endOfLineCharacter and friends
//	  (code contributed by Randy Bradley)
//	- cleaned up accessor methods; moved deprecated methods to "Deprecated" category
//	- -setSpeed: does support arbitrary values on 10.4 and later; returns YES on success, NO otherwiese
//  2006-08-16 Andreas Mayer
//	- cleaned up the code and removed some (presumably) unnecessary locks
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean
//	2009-3-20 Pat O'Keefe
//	- fixed setSpeed method


/*
 * Standard speeds defined in termios.h
 *
#define B0	0
#define B50	50
#define B75	75
#define B110	110
#define B134	134
#define B150	150
#define B200	200
#define B300	300
#define B600	600
#define B1200	1200
#define	B1800	1800
#define B2400	2400
#define B4800	4800
#define B7200	7200
#define B9600	9600
#define B14400	14400
#define B19200	19200
#define B28800	28800
#define B38400	38400
#define B57600	57600
#define B76800	76800
#define B115200	115200
#define B230400	230400
 */

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

#import <Foundation/Foundation.h>

#define	AMSerialOptionServiceName @"AMSerialOptionServiceName"
#define	AMSerialOptionSpeed @"AMSerialOptionSpeed"
#define	AMSerialOptionDataBits @"AMSerialOptionDataBits"
#define	AMSerialOptionParity @"AMSerialOptionParity"
#define	AMSerialOptionStopBits @"AMSerialOptionStopBits"
#define	AMSerialOptionInputFlowControl @"AMSerialOptionInputFlowControl"
#define	AMSerialOptionOutputFlowControl @"AMSerialOptionOutputFlowControl"
#define	AMSerialOptionEcho @"AMSerialOptionEcho"
#define	AMSerialOptionCanonicalMode @"AMSerialOptionCanonicalMode"

// By default, debug code is preprocessed out.  If you would like to compile with debug code enabled,
// "#define AMSerialDebug" before including any AMSerialPort headers, as in your prefix header

typedef enum {	
	kAMSerialParityNone = 0,
	kAMSerialParityOdd = 1,
	kAMSerialParityEven = 2
} AMSerialParity;

typedef enum {	
	kAMSerialStopBitsOne = 1,
	kAMSerialStopBitsTwo = 2
} AMSerialStopBits;

// Private constant
#define AMSER_MAXBUFSIZE  512UL//4096UL

extern NSString *const AMSerialErrorDomain;

@interface NSObject (AMSerialDelegate)
- (void)serialPortReadData:(NSDictionary *)dataDictionary;
- (void)serialPortWriteProgress:(NSDictionary *)dataDictionary;
@end

@interface AMSerialPort : NSObject
{
@private
	NSString *bsdPath;
	NSString *serviceName;
	NSString *serviceType;
	int fileDescriptor;
	struct termios * __strong options;
	struct termios * __strong originalOptions;
	NSMutableDictionary *optionsDictionary;
	NSFileHandle *fileHandle;
	BOOL gotError;
	int	lastError;
	id owner;
	// used by AMSerialPortAdditions only:
	char * __strong buffer;
	id am_readTarget;
	SEL am_readSelector;
	NSTimeInterval readTimeout; // for public blocking read methods and doRead
	fd_set * __strong readfds;
	id delegate;
	BOOL delegateHandlesReadInBackground;
	BOOL delegateHandlesWriteInBackground;
	
	NSLock *writeLock;
	BOOL stopWriteInBackground;
	int countWriteInBackgroundThreads;
	NSLock *readLock;
	BOOL stopReadInBackground;
	int countReadInBackgroundThreads;
	NSLock *closeLock;
}

- (id)init:(NSString *)path withName:(NSString *)name type:(NSString *)serialType;
// initializes port
// path is a bsdPath
// name is an IOKit service name
// type is an IOKit service type

- (NSString *)bsdPath;
// bsdPath (e.g. '/dev/cu.modem')

- (NSString *)name;
// IOKit service name (e.g. 'modem')

- (NSString *)type;
// IOKit service type (e.g. kIOSerialBSDRS232Type)

- (NSDictionary *)properties;
// IORegistry entry properties - see IORegistryEntryCreateCFProperties()


- (BOOL)isOpen;
// YES if port is open

- (AMSerialPort *)obtainBy:(id)sender;
// get this port exclusively; NULL if it's not free

- (void)free;
// give it back (and close the port if still open)

- (BOOL)available;
// check if port is free and can be obtained

- (id)owner;
// who obtained the port?


- (NSFileHandle *)open;
// opens port for read and write operations
// to actually read or write data use the methods provided by NSFileHandle
// (alternatively you may use those from AMSerialPortAdditions)

- (void)close;
// close port - no more read or write operations allowed

- (BOOL)drainInput;
- (BOOL)flushInput:(BOOL)fIn Output:(BOOL)fOut;	// (fIn or fOut) must be YES
- (BOOL)sendBreak;

- (BOOL)setDTR;
// set DTR - not yet tested!

- (BOOL)clearDTR;
// clear DTR - not yet tested!

// read and write serial port settings through a dictionary

- (NSDictionary *)options;
// will open the port to get options if neccessary

- (void)setOptions:(NSDictionary *)options;
// AMSerialOptionServiceName HAS to match! You may NOT switch ports using this
// method.

// reading and setting parameters is only useful if the serial port is already open
- (long)speed;
- (BOOL)setSpeed:(long)speed;

- (unsigned long)dataBits;
- (void)setDataBits:(unsigned long)bits;	// 5 to 8 (5 may not work)

- (AMSerialParity)parity;
- (void)setParity:(AMSerialParity)newParity;

- (AMSerialStopBits)stopBits;
- (void)setStopBits:(AMSerialStopBits)numBits;

- (BOOL)echoEnabled;
- (void)setEchoEnabled:(BOOL)echo;

- (BOOL)RTSInputFlowControl;
- (void)setRTSInputFlowControl:(BOOL)rts;

- (BOOL)DTRInputFlowControl;
- (void)setDTRInputFlowControl:(BOOL)dtr;

- (BOOL)CTSOutputFlowControl;
- (void)setCTSOutputFlowControl:(BOOL)cts;

- (BOOL)DSROutputFlowControl;
- (void)setDSROutputFlowControl:(BOOL)dsr;

- (BOOL)CAROutputFlowControl;
- (void)setCAROutputFlowControl:(BOOL)car;

- (BOOL)hangupOnClose;
- (void)setHangupOnClose:(BOOL)hangup;

- (BOOL)localMode;
- (void)setLocalMode:(BOOL)local;	// YES = ignore modem status lines

- (BOOL)canonicalMode;
- (void)setCanonicalMode:(BOOL)flag;

- (char)endOfLineCharacter;
- (void)setEndOfLineCharacter:(char)eol;

- (void)clearError;			// call this before changing any settings
- (BOOL)commitChanges;	// call this after using any of the above set... functions
- (int)errorCode;				// if -commitChanges returns NO, look here for further info

// setting the delegate (for background reading/writing)

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

// time out for blocking reads in seconds
- (NSTimeInterval)readTimeout;
- (void)setReadTimeout:(NSTimeInterval)aReadTimeout;

- (void)readTimeoutAsTimeval:(struct timeval*)timeout;


@end
