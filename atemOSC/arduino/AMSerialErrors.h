/*
 *  AMSerialErrors.h
 *
 *  Created by Andreas on 27.07.06.
 *  Copyright 2006 Andreas Mayer. All rights reserved.
 *
 */


enum {
	kAMSerialErrorNone = 0,
	kAMSerialErrorFatal = 99,
	
	// reading only
	kAMSerialErrorTimeout = 100,
	kAMSerialErrorInternalBufferFull = 101,
	
	// writing only
	kAMSerialErrorNoDataToWrite = 200,
	kAMSerialErrorOnlySomeDataWritten = 201,
};

enum {
	// reading only
	kAMSerialEndOfStream = 0,
	kAMSerialStopCharReached = 1,
	kAMSerialStopLengthReached = 2,
	kAMSerialStopLengthExceeded = 3,
};
