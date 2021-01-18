//
//  OSCEndpoint.h
//  AtemOSC
//
//  Created by Peter Steffey on 1/11/20.
//

#import <Foundation/Foundation.h>
#import "VVOSC/VVOSC.h"
#import "Switcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSCEndpoint : NSObject
	@property(nonatomic, assign) NSString *addressTemplate;
	@property(nonatomic, assign) NSString *helpText;
	@property(nonatomic, assign) NSString *label;
	@property(nonatomic) OSCValueType valueType;
	@property(nonatomic, copy) void (^handler)(Switcher *s, NSDictionary *, OSCValue *);
@end

NS_ASSUME_NONNULL_END
