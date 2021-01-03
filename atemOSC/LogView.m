//
//  LogView.m
//  AtemOSC
//
//  Created by Peter Steffey on 1/1/21.
//

#import "LogView.h"

@implementation LogView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder])
	{
		[self setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
		[self setMaterial:NSVisualEffectMaterialDark];
		[self setState:NSVisualEffectStateActive];
		return self;
	}
	return nil;
}

@end
