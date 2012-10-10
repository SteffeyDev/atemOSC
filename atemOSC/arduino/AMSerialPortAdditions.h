//
//  AMSerialPortAdditions.h
//
//  Created by Andreas on Thu May 02 2002.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-10-04 Andreas Mayer
//  - readDataInBackgroundWithTarget:selector: and writeDataInBackground: added
//  2002-10-10 Andreas Mayer
//	- stopWriteInBackground added
//  2002-10-17 Andreas Mayer
//	- numberOfWriteInBackgroundThreads added
//  2002-10-25 Andreas Mayer
//	- readDataInBackground and stopReadInBackground added
//  2004-02-10 Andreas Mayer
//    - replaced notifications for background reading/writing with direct messages to delegate
//      see informal protocol
//  2004-08-18 Andreas Mayer
//	- readStringOfLength: added (suggested by Michael Beck)
//  2006-08-16 Andreas Mayer / Sean McBride
//	- changed interface for blocking read/write access significantly
//	- fixed -checkRead and renamed it to -bytesAvailable
//	- see AMSerialPort_Deprecated for old interfaces
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean

#import "AMSDKCompatibility.h"

#import <Foundation/Foundation.h>
#import "AMSerialPort.h"


@interface AMSerialPort (AMSerialPortAdditions)

// returns the number of bytes available in the input buffer
// Be careful how you use this information, it may be out of date just after you get it
- (int)bytesAvailable;

- (void)waitForInput:(id)target selector:(SEL)selector;


// all blocking reads returns after [self readTimout] seconds elapse, at the latest
- (NSData *)readAndReturnError:(NSError **)error;

// returns after 'bytes' bytes are read
- (NSData *)readBytes:(NSUInteger)bytes error:(NSError **)error;

// returns when 'stopChar' is encountered
- (NSData *)readUpToChar:(char)stopChar error:(NSError **)error;

// returns after 'bytes' bytes are read or if 'stopChar' is encountered, whatever comes first
- (NSData *)readBytes:(NSUInteger)bytes upToChar:(char)stopChar error:(NSError **)error;

// data read will be converted into an NSString, using the given encoding
// NOTE: encodings that take up more than one byte per character may fail if only a part of the final string was received
- (NSString *)readStringUsingEncoding:(NSStringEncoding)encoding error:(NSError **)error;

- (NSString *)readBytes:(NSUInteger)bytes usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;

// NOTE: 'stopChar' has to be a byte value, using the given encoding; you can not wait for an arbitrary character from a multi-byte encoding
- (NSString *)readUpToChar:(char)stopChar usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;

- (NSString *)readBytes:(NSUInteger)bytes upToChar:(char)stopChar usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;

// write to the serial port; NO if an error occured
- (BOOL)writeData:(NSData *)data error:(NSError **)error;

- (BOOL)writeString:(NSString *)string usingEncoding:(NSStringEncoding)encoding error:(NSError **)error;


- (void)readDataInBackground;
//
// Will send serialPortReadData: to delegate
// the dataDictionary object will contain these entries:
// 1. "serialPort": the AMSerialPort object that sent the message
// 2. "data": (NSData *)data - received data

- (void)stopReadInBackground;

- (void)writeDataInBackground:(NSData *)data;
//
// Will send serialPortWriteProgress: to delegate if task lasts more than
// approximately three seconds.
// the dataDictionary object will contain these entries:
// 1. "serialPort": the AMSerialPort object that sent the message
// 2. "value": (NSNumber *)value - bytes sent
// 3. "total": (NSNumber *)total - bytes total

- (void)stopWriteInBackground;

- (int)numberOfWriteInBackgroundThreads;


@end
