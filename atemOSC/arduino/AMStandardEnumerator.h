//
//  AMStandardEnumerator.h
//
//  Created by Andreas on Mon Aug 04 2003.
//  Copyright (c) 2003 Andreas Mayer. All rights reserved.
//
//  2007-10-26 Sean McBride
//  - made code 64 bit and garbage collection clean

#import "AMSDKCompatibility.h"

#import <Foundation/Foundation.h>

typedef NSUInteger (*CountMethod)(id, SEL);
typedef id (*NextObjectMethod)(id, SEL, NSUInteger);

@interface AMStandardEnumerator : NSEnumerator
{
@private
	id collection;
	SEL countSelector;
	SEL nextObjectSelector;
	CountMethod count;
	NextObjectMethod nextObject;
	NSUInteger position;
}

// Designated initializer
- (id)initWithCollection:(id)theCollection countSelector:(SEL)theCountSelector objectAtIndexSelector:(SEL)theObjectSelector;


@end
