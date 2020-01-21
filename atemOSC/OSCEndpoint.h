//
//  OSCEndpoint.h
//  AtemOSC
//
//  Created by Peter Steffey on 1/11/20.
//

#import <Foundation/Foundation.h>
#import "VVOSC/VVOSC.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSCEndpoint : NSObject
	@property(nonatomic) NSString *addressTemplate;
	@property(nonatomic) NSString *helpText;
	@property(nonatomic) NSString *label;
	@property(nonatomic) OSCValueType valueType;
	@property(nonatomic, copy) void (^handler)(NSDictionary *, OSCValue *);
@end

NS_ASSUME_NONNULL_END
