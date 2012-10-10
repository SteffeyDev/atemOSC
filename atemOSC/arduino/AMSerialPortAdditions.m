//
//  AMSerialPortAdditions.m
//
//  Created by Andreas on Thu May 02 2002.
//  Copyright (c) 2001 Andreas Mayer. All rights reserved.
//
//  2002-07-02 Andreas Mayer
//	- initialize buffer in readString
//  2002-10-04 Andreas Mayer
//  - readDataInBackgroundWithTarget:selector: and writeDataInBackground: added
//  2002-10-10 Andreas Mayer
//	- stopWriteInBackground added
//	- send notifications about sent data through distributed notification center
//  2002-10-17 Andreas Mayer
//	- numberOfWriteInBackgroundThreads added
//	- if total write time will exceed 3 seconds, send
//		CommXWriteInBackgroundProgressNotification without delay
//  2002-10-25 Andreas Mayer
//	- readDataInBackground and stopReadInBackground added
//  2004-08-18 Andreas Mayer
//	- readStringOfLength: added (suggested by Michael Beck)
//  2005-04-11 Andreas Mayer
//	-  attempt at a fix for readDataInBackgroundThread - fileDescriptor could already be closed
//		(thanks to David Bainbridge for the bug report) does not work as of yet
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean


#import "AMSDKCompatibility.h"

#import <sys/ioctl.h>
#import <sys/filio.h>

#import "AMSerialPortAdditions.h"
#import "AMSerialErrors.h"


@interface AMSerialPort (AMSerialPortAdditionsPrivate)
- (void)readDataInBackgroundThread;
- (void)writeDataInBackgroundThread:(NSData *)data;
- (id)am_readTarget;
- (void)am_setReadTarget:(id)newReadTarget;
- (NSData *)readAndStopAfterBytes:(BOOL)stopAfterBytes bytes:(NSUInteger)bytes stopAtChar:(BOOL)stopAtChar stopChar:(char)stopChar error:(NSError **)error;
- (void)reportProgress:(NSUInteger)progress dataLen:(NSUInteger)dataLen;
@end


@implementation AMSerialPort (AMSerialPortAdditions)


// ============================================================
#pragma mark -
#pragma mark blocking IO
// ============================================================

- (void)doRead:(NSTimer *)timer
{
	(void)timer;
	
#ifdef AMSerialDebug
	NSLog(@"doRead");
#endif
	int res;
	struct timeval timeout;
	if (fileDescriptor >= 0) {
		FD_ZERO(readfds);
		FD_SET(fileDescriptor, readfds);
		[self readTimeoutAsTimeval:&timeout];
		res = select(fileDescriptor+1, readfds, nil, nil, &timeout);
		if (res >= 1) {
			NSString *readStr = [self readStringUsingEncoding:NSUTF8StringEncoding error:NULL];
			[[self am_readTarget] performSelector:am_readSelector withObject:readStr];
			[self am_setReadTarget:nil];
		} else {
			[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self repeats:NO];
		}
	} else {
		// file already closed
		[self am_setReadTarget:nil];
	}
}

// all blocking reads returns after [self readTimout] seconds elapse, at the latest
- (NSData *)readAndReturnError:(NSError **)error
{
	NSData *result = [self readAndStopAfterBytes:NO bytes:0 stopAtChar:NO stopChar:0 error:error];
	return result;
}

// returns after 'bytes' bytes are read
- (NSData *)readBytes:(NSUInteger)bytes error:(NSError **)error
{
	NSData *result = [self readAndStopAfterBytes:YES bytes:bytes stopAtChar:NO stopChar:0 error:error];
	return result;
}

// returns when 'stopChar' is encountered
- (NSData *)readUpToChar:(char)stopChar error:(NSError **)error
{
	NSData *result = [self readAndStopAfterBytes:NO bytes:0 stopAtChar:YES stopChar:stopChar error:error];
	return result;
}

// returns after 'bytes' bytes are read or if 'stopChar' is encountered, whatever comes first
- (NSData *)readBytes:(NSUInteger)bytes upToChar:(char)stopChar error:(NSError **)error
{
	NSData *result = [self readAndStopAfterBytes:YES bytes:bytes stopAtChar:YES stopChar:stopChar error:error];
	return result;
}

// data read will be converted into an NSString, using the given encoding
// NOTE: encodings that take up more than one byte per character may fail if only a part of the final string was received
- (NSString *)readStringUsingEncoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSString *result = nil;
	NSData *data = [self readAndStopAfterBytes:NO bytes:0 stopAtChar:NO stopChar:0 error:error];
	if (data) {
		result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	}
	return result;
}

- (NSString *)readBytes:(NSUInteger)bytes usingEncoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSString *result = nil;
	NSData *data = [self readAndStopAfterBytes:YES bytes:bytes stopAtChar:NO stopChar:0 error:error];
	if (data) {
		result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	}
	return result;
}

// NOTE: 'stopChar' has to be a byte value, using the given encoding; you can not wait for an arbitrary character from a multi-byte encoding
- (NSString *)readUpToChar:(char)stopChar usingEncoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSString *result = nil;
	NSData *data = [self readAndStopAfterBytes:NO bytes:0 stopAtChar:YES stopChar:stopChar error:error];
	if (data) {
		result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	}
	return result;
}

- (NSString *)readBytes:(NSUInteger)bytes upToChar:(char)stopChar usingEncoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSString *result = nil;
	NSData *data = [self readAndStopAfterBytes:YES bytes:bytes stopAtChar:YES stopChar:stopChar error:error];
	if (data) {
		result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
	}
	return result;
}


// write to the serial port; NO if an error occured
- (BOOL)writeData:(NSData *)data error:(NSError **)error
{
	BOOL result = NO;

	const char *dataBytes = (const char*)[data bytes];
	NSUInteger dataLen = [data length];
	ssize_t bytesWritten = 0;
	int errorCode = kAMSerialErrorNone;
	if (dataBytes && (dataLen > 0)) {
		bytesWritten = write(fileDescriptor, dataBytes, dataLen);
		if (bytesWritten < 0) {
			errorCode = kAMSerialErrorFatal;
		} else if ((NSUInteger)bytesWritten == dataLen) {
			result = YES;
		} else {
			errorCode = kAMSerialErrorOnlySomeDataWritten;
		}
	} else {
		errorCode = kAMSerialErrorNoDataToWrite;
	}
	if (error) {
		NSDictionary *userInfo = nil;
		if (bytesWritten > 0) {
			NSNumber* bytesWrittenNum = [NSNumber numberWithUnsignedLongLong:bytesWritten];
			userInfo = [NSDictionary dictionaryWithObject:bytesWrittenNum forKey:@"bytesWritten"];
		}
		*error = [NSError errorWithDomain:AMSerialErrorDomain code:errorCode userInfo:userInfo];
	}
		
	return result;
}

- (BOOL)writeString:(NSString *)string usingEncoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSData *data = [string dataUsingEncoding:encoding];
	return [self writeData:data error:error];
}

- (int)bytesAvailable
{
#ifdef AMSerialDebug
	NSLog(@"bytesAvailable");
#endif

	// yes, that cast is correct.  ioctl() is declared to take a char* but should be void* as really it
	// depends on the 2nd parameter.  Ahhh, I love crappy old UNIX APIs :)
	int result = 0;
	int err = ioctl(fileDescriptor, FIONREAD, (char *)&result);
	if (err != 0) {
		result = -1;
	}
	return result;
}


- (void)waitForInput:(id)target selector:(SEL)selector
{
#ifdef AMSerialDebug
	NSLog(@"waitForInput");
#endif
	[self am_setReadTarget:target];
	am_readSelector = selector;
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self repeats:NO];
}

// ============================================================
#pragma mark -
#pragma mark threaded IO
// ============================================================

- (void)readDataInBackground
{
#ifdef AMSerialDebug
	NSLog(@"readDataInBackground");
#endif
	if (delegateHandlesReadInBackground) {
		countReadInBackgroundThreads++;
		[NSThread detachNewThreadSelector:@selector(readDataInBackgroundThread) toTarget:self withObject:nil];
	} else {
		// ... throw exception?
	}
}

- (void)stopReadInBackground
{
#ifdef AMSerialDebug
	NSLog(@"stopReadInBackground");
#endif
	stopReadInBackground = YES;
}

- (void)writeDataInBackground:(NSData *)data
{
#ifdef AMSerialDebug
	NSLog(@"writeDataInBackground");
#endif
	if (delegateHandlesWriteInBackground) {
		countWriteInBackgroundThreads++;
		[NSThread detachNewThreadSelector:@selector(writeDataInBackgroundThread:) toTarget:self withObject:data];
	} else {
		// ... throw exception?
	}
}

- (void)stopWriteInBackground
{
#ifdef AMSerialDebug
	NSLog(@"stopWriteInBackground");
#endif
	stopWriteInBackground = YES;
}

- (int)numberOfWriteInBackgroundThreads
{
	return countWriteInBackgroundThreads;
}


@end

#pragma mark -

@implementation AMSerialPort (AMSerialPortAdditionsPrivate)

// ============================================================
#pragma mark -
#pragma mark threaded methods
// ============================================================

- (void)readDataInBackgroundThread
{
	NSData *data = nil;
	void *localBuffer;
	ssize_t bytesRead = 0;
	fd_set *localReadFDs = NULL;

	[readLock lock];	// read in sequence
	//NSLog(@"readDataInBackgroundThread - [readLock lock]");

	localBuffer = malloc(AMSER_MAXBUFSIZE);
	stopReadInBackground = NO;
	NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
	[closeLock lock];
	if ((fileDescriptor >= 0) && (!stopReadInBackground)) {
		//NSLog(@"readDataInBackgroundThread - [closeLock lock]");
		localReadFDs = (fd_set*)malloc(sizeof(fd_set));
		FD_ZERO(localReadFDs);
		FD_SET(fileDescriptor, localReadFDs);
		[closeLock unlock];
		//NSLog(@"readDataInBackgroundThread - [closeLock unlock]");
		int res = select(fileDescriptor+1, localReadFDs, nil, nil, nil); // timeout);
		if ((res >= 1) && (fileDescriptor >= 0)) {
			//bytesRead = read(fileDescriptor, localBuffer, AMSER_MAXBUFSIZE);
		}
		//FIXME: This was modified on 3-20-09 by Pat O'Keefe for a particular application...swap comments for normal operation
		//data = [NSData dataWithBytes:localBuffer length:bytesRead];
		data = [self readUpToChar:'\n' error:NULL];
		[delegate performSelectorOnMainThread:@selector(serialPortReadData:) withObject:[NSDictionary dictionaryWithObjectsAndKeys: self, @"serialPort", data, @"data", nil] waitUntilDone:YES];//was NO
	} else {
		[closeLock unlock];
	}
	[localAutoreleasePool release];
	if (localReadFDs)
		free(localReadFDs);
	if (localBuffer)
		free(localBuffer);

	countReadInBackgroundThreads--;

	[readLock unlock];
	//NSLog(@"readDataInBackgroundThread - [readLock unlock]");

}

/* new version - does not work yet
- (void)readDataInBackgroundThread
{
	NSData *data = nil;
	void *localBuffer;
	int bytesRead = 0;
	fd_set *localReadFDs;

#ifdef AMSerialDebug
	NSLog(@"readDataInBackgroundThread: %@", [NSThread currentThread]);
#endif
	localBuffer = malloc(AMSER_MAXBUFSIZE);
	[stopReadInBackgroundLock lock];
	stopReadInBackground = NO;
	//NSLog(@"stopReadInBackground set to NO: %@", [NSThread currentThread]);
	[stopReadInBackgroundLock unlock];
	//NSLog(@"attempt readLock: %@", [NSThread currentThread]);
	[readLock lock];	// write in sequence
	//NSLog(@"readLock locked: %@", [NSThread currentThread]);
	//NSLog(@"attempt closeLock: %@", [NSThread currentThread]);
	[closeLock lock];
	//NSLog(@"closeLock locked: %@", [NSThread currentThread]);
	if (!stopReadInBackground && (fileDescriptor >= 0)) {
		NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
		localReadFDs = malloc(sizeof(*localReadFDs));
		FD_ZERO(localReadFDs);
		FD_SET(fileDescriptor, localReadFDs);
		int res = select(fileDescriptor+1, localReadFDs, nil, nil, nil); // timeout);
		if (res >= 1) {
#ifdef AMSerialDebug
			NSLog(@"attempt read: %@", [NSThread currentThread]);
#endif
			bytesRead = read(fileDescriptor, localBuffer, AMSER_MAXBUFSIZE);
		}
#ifdef AMSerialDebug
		NSLog(@"data read: %@", [NSThread currentThread]);
#endif
		data = [NSData dataWithBytes:localBuffer length:bytesRead];
#ifdef AMSerialDebug
		NSLog(@"send AMSerialReadInBackgroundDataMessage");
#endif
		[delegate performSelectorOnMainThread:@selector(serialPortReadData:) withObject:[NSDictionary dictionaryWithObjectsAndKeys: self, @"serialPort", data, @"data", nil] waitUntilDone:NO];
		free(localReadFDs);
		[localAutoreleasePool release];
	} else {
#ifdef AMSerialDebug
		NSLog(@"read stopped: %@", [NSThread currentThread]);
#endif
	}

	[closeLock unlock];
	//NSLog(@"closeLock unlocked: %@", [NSThread currentThread]);
	[readLock unlock];
	//NSLog(@"readLock unlocked: %@", [NSThread currentThread]);
	[countReadInBackgroundThreadsLock lock];
	countReadInBackgroundThreads--;
	[countReadInBackgroundThreadsLock unlock];
	
	free(localBuffer);
}
*/

- (void)writeDataInBackgroundThread:(NSData *)data
{
	
#ifdef AMSerialDebug
	NSLog(@"writeDataInBackgroundThread");
#endif
	void *localBuffer;
	NSUInteger pos;
	NSUInteger bufferLen;
	NSUInteger dataLen;
	ssize_t written;
	NSDate *nextNotificationDate;
	BOOL notificationSent = NO;
	long speed;
	long estimatedTime;
	BOOL error = NO;
	
	NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];

	[data retain];
	localBuffer = malloc(AMSER_MAXBUFSIZE);
	stopWriteInBackground = NO;
	[writeLock lock];	// write in sequence
	pos = 0;
	dataLen = [data length];
	speed = [self speed];
	estimatedTime = (dataLen*8)/speed;
	if (estimatedTime > 3) { // will take more than 3 seconds
		notificationSent = YES;
		[self reportProgress:pos dataLen:dataLen];
		nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
	} else {
		nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:2.0];
	}
	while (!stopWriteInBackground && (pos < dataLen) && !error) {
		bufferLen = MIN(AMSER_MAXBUFSIZE, dataLen-pos);

		[data getBytes:localBuffer range:NSMakeRange(pos, bufferLen)];
		written = write(fileDescriptor, localBuffer, bufferLen);
		error = (written == 0); // error condition
		if (error)
			break;
		pos += written;

		if ([(NSDate *)[NSDate date] compare:nextNotificationDate] == NSOrderedDescending) {
			if (notificationSent || (pos < dataLen)) { // not for last block only
				notificationSent = YES;
				[self reportProgress:pos dataLen:dataLen];
				nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
			}
		}
	}
	if (notificationSent) {
		[self reportProgress:pos dataLen:dataLen];
	}
	stopWriteInBackground = NO;
	[writeLock unlock];
	countWriteInBackgroundThreads--;
	
	free(localBuffer);
	[data release];
	[localAutoreleasePool release];
}

- (id)am_readTarget
{
	return am_readTarget; 
}

- (void)am_setReadTarget:(id)newReadTarget
{
	if (am_readTarget != newReadTarget) {
		[newReadTarget retain];
		[am_readTarget release];
		am_readTarget = newReadTarget;
	}
}

// Low-level blocking read method.
// This method reads from the serial port and blocks as necessary, it returns when:
//  - [self readTimeout] seconds has elapsed
//  - if stopAfterBytes is YES, when 'bytesToRead' bytes have been read
//  - if stopAtChar is YES, when 'stopChar' is found at the end of the read buffer
//  - a fatal error occurs
//
// Upon return: as long as some data was actually read, and no serious error occured, an autoreleased NSData
// object with that data is created and returned, otherwise nil is.
- (NSData *)readAndStopAfterBytes:(BOOL)stopAfterBytes bytes:(NSUInteger)bytesToRead stopAtChar:(BOOL)stopAtChar stopChar:(char)stopChar error:(NSError **)error
{
	NSData *result = nil;
	
	struct timeval timeout;
	NSUInteger bytesRead = 0;
	BOOL stop = NO;
	int errorCode = kAMSerialErrorNone;
	int endCode = kAMSerialEndOfStream;
	NSError *underlyingError = nil;
	
	// Note the time that we start
	NSDate *startTime = [NSDate date];
	
	// How long, in total, do we block before timing out?
	NSTimeInterval totalTimeout = [self readTimeout];

	// This value will be decreased each time through the loop
	NSTimeInterval remainingTimeout = totalTimeout;
	
	while (!stop) {
		if (remainingTimeout <= 0.0) {
			stop = YES;
			errorCode = kAMSerialErrorTimeout;
			break;
		} else {
			// Convert from NSTimeInterval to struct timeval
			double numSecs = trunc(remainingTimeout);
			double numUSecs = (remainingTimeout-numSecs)*1000000.0;
			timeout.tv_sec = (time_t)lrint(numSecs);
			timeout.tv_usec = (suseconds_t)lrint(numUSecs);
#ifdef AMSerialDebug
			NSLog(@"timeout: %fs = %ds and %dus", remainingTimeout, timeout.tv_sec, timeout.tv_usec);
#endif
			
			// If the remaining time is so small that it has rounded to zero, bump it up to 1 microsec.
			// Why?  Because passing a zeroed timeval to select() indicates that we want to poll, but we don't.
			if ((timeout.tv_sec == 0) && (timeout.tv_usec == 0)) {
				timeout.tv_usec = 1;
			}
			FD_ZERO(readfds);
			FD_SET(fileDescriptor, readfds);
			[self readTimeoutAsTimeval:&timeout];
			int selectResult = select(fileDescriptor+1, readfds, NULL, NULL, &timeout);
			if (selectResult == -1) {
				stop = YES;
				errorCode = kAMSerialErrorFatal;
				break;
			} else if (selectResult == 0) {
				stop = YES;
				errorCode = kAMSerialErrorTimeout;
				break;
			} else {
				size_t	sizeToRead;
				if (stopAfterBytes) {
					sizeToRead = (MIN(bytesToRead, AMSER_MAXBUFSIZE))-bytesRead;
				} else {
					sizeToRead = AMSER_MAXBUFSIZE-bytesRead;
				}
				ssize_t	readResult = read(fileDescriptor, buffer+bytesRead, sizeToRead);
				if (readResult > 0) {
					bytesRead += readResult;
					if (stopAfterBytes) {
						if (bytesRead == bytesToRead) {
							stop = YES;
							endCode = kAMSerialStopLengthReached;
							break;
						} else if (bytesRead > bytesToRead) {
							stop = YES;
							endCode = kAMSerialStopLengthExceeded;
							break;
						}
					}
					if (stopAtChar && (buffer[bytesRead-1] == stopChar)) {
						stop = YES;
						endCode = kAMSerialStopCharReached;
						break;
					}
					if (bytesRead >= AMSER_MAXBUFSIZE) {
						stop = YES;
						errorCode = kAMSerialErrorInternalBufferFull;
						break;
					}
				} else if (readResult == 0) {
					// Should not be possible since select() has indicated data is available
					stop = YES;
					errorCode = kAMSerialErrorFatal;
					break;
				} else {
					stop = YES;
					// Make underlying error
					underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:readResult userInfo:nil];
					errorCode = kAMSerialErrorFatal;
					break;
				}
			}
			
			// Reduce the timeout value by the amount of time actually spent so far
			remainingTimeout = totalTimeout - [[NSDate date] timeIntervalSinceDate:startTime];
		}
	}
	
	if (error) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithUnsignedLongLong:bytesRead] forKey:@"bytesRead"];
		if (underlyingError) {
			[userInfo setObject:underlyingError forKey:NSUnderlyingErrorKey];
		}
		if (errorCode == kAMSerialErrorNone) {
			[userInfo setObject:[NSNumber numberWithInt:endCode] forKey:@"endCode"];
		}
		*error = [NSError errorWithDomain:AMSerialErrorDomain code:errorCode userInfo:userInfo];
	}
	if ((bytesRead > 0) && (errorCode != kAMSerialErrorFatal)) {
		result = [NSData dataWithBytes:buffer length:bytesRead];
	}
	
	return result;
}

- (void)reportProgress:(NSUInteger)progress dataLen:(NSUInteger)dataLen
{
#ifdef AMSerialDebug
	NSLog(@"send AMSerialWriteInBackgroundProgressMessage");
#endif
	[delegate performSelectorOnMainThread:@selector(serialPortWriteProgress:) withObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			self, @"serialPort",
			[NSNumber numberWithUnsignedLongLong:progress], @"value",
			[NSNumber numberWithUnsignedLongLong:dataLen], @"total", nil]
		waitUntilDone:NO];
}

@end
