//
//  ExceptionHandler.m
//  AtemOSC
//
//  Created by Peter Steffey on 10/8/21.
//

#import "BugsnagExceptionHandler.h"
#import <Bugsnag/Bugsnag.h>

@implementation BugsnagExceptionHandler

- (void)reportException:(NSException *)theException {
	[Bugsnag notify:theException];
	[super reportException:theException];
}

@end
