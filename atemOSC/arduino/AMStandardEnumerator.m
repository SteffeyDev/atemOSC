//
//  AMStandardEnumerator.m
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean

#import "AMSDKCompatibility.h"

#import "AMStandardEnumerator.h"


@implementation AMStandardEnumerator

// Designated initializer
- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector
{
	self = [super init];
	if (self) {
		collection = [theCollection retain];
		countSelector = theCountSelector;
		count = (CountMethod)[collection methodForSelector:countSelector];
		nextObjectSelector = theObjectSelector;
		nextObject = (NextObjectMethod)[collection methodForSelector:nextObjectSelector];
		position = 0;
	}
	return self;
}

#ifndef __OBJC_GC__

- (void)dealloc
{
	[collection release];
	[super dealloc];
}

#endif

- (id)nextObject
{
	if (position >= count(collection, countSelector))
		return nil;

	return (nextObject(collection, nextObjectSelector, position++));
}

- (NSArray *)allObjects
{
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
	id object;
	while ((object = [self nextObject]) != nil)
		[result addObject:object];
	return result;
}

@end
