//
//  Utilities.cpp
//  AtemOSC
//
//  Created by Peter Steffey on 11/4/17.
//

#include "Utilities.h"
#import "AppDelegate.h"

bool isMacroValid(Switcher *s, uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	bool isValid;
	if ([s mMacroPool])
	{
		result = [s mMacroPool]->IsValid(index, &isValid);
		switch (result)
		{
			case S_OK:
				return isValid;
			case E_INVALIDARG:
				[appDel logMessage:[NSString stringWithFormat:@"Could not check whether the Macro at index %d is valid because the index is invalid.", index]];
				break;
			default:
				[appDel logMessage:[NSString stringWithFormat:@"Could not check whether the Macro at index %d is valid.", index]];
				break;
		}
		return NO;
	}
	return NO;
}

bool runMacroAtIndex(Switcher *s, uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	if ([s mMacroControl])
	{
		if (!isMacroValid(s, index))
		{
			[appDel logMessage:[NSString stringWithFormat:@"Could not run the Macro at index %d because it is not valid.", index]];
			return NO;
		}
		
		result = [s mMacroControl]->Run(index);
		switch (result)
		{
			case S_OK:
				return true;
			case E_INVALIDARG:
				[appDel logMessage:[NSString stringWithFormat:@"Could not run the Macro at index %d because the index is invalid.", index]];
				break;
			case E_FAIL:
				[appDel logMessage:[NSString stringWithFormat:@"Could not run the Macro at index %d.", index]];
				break;
			default:
				[appDel logMessage:[NSString stringWithFormat:@"Could not run the Macro at index %d.", index]];
				break;
		}
		return NO;
	}
	return NO;
}

bool stopRunningMacro(Switcher *s)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	if ([s mMacroControl])
	{
		result = [s mMacroControl]->StopRunning();
		switch (result)
		{
			case S_OK:
				return YES;
			default:
				[appDel logMessage:@"Could not stop the current Macro."];
				break;
		}
		return NO;
	}
	return NO;
}

uint32_t getMaxNumberOfMacros(Switcher *s)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	uint32_t maxNumberOfMacros = 0;
	if ([s mMacroPool])
	{
		if (S_OK == [s mMacroPool]->GetMaxCount(&maxNumberOfMacros))
			return maxNumberOfMacros;
		else
			[appDel logMessage:@"Could not get max the number of Macros available."];
	}
	return maxNumberOfMacros;
}

NSString* getNameOfMacro(Switcher *s, uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	CFStringRef name = NULL;
	result = [s mMacroPool]->GetName(index, &name);
	switch (result)
	{
		case S_OK:
			return (__bridge NSString *)name;
		case E_INVALIDARG:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the name of the Macro at index %d because the index is invalid.", index]];
			break;
		case E_OUTOFMEMORY:
			[appDel logMessage:[NSString stringWithFormat:@"Insufficient memory to get the name of the Macro at index %d.", index]];
			break;
		default:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the name of the Macro at index %d.", index]];
	}
	return (__bridge NSString *)name;
}

NSString* getDescriptionOfMacro(Switcher *s, uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	CFStringRef description;
	result = [s mMacroPool]->GetDescription(index, &description);
	switch (result)
	{
		case S_OK:
			return (__bridge NSString *)description;
		case E_INVALIDARG:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the description of the Macro at index %d because the index is invalid.", index]];
			break;
		case E_OUTOFMEMORY:
			[appDel logMessage:[NSString stringWithFormat:@"Insufficient memory to get the description of the Macro at index %d.", index]];
			break;
		default:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the description of the Macro at index %d.", index]];
	}
	return (__bridge NSString *)description;
}


void activateChannel(Switcher *s, int me, int channel, bool program)
{
	BMDSwitcherInputId InputId = channel;
	if (program) {
		@try
		{
			[s mMixEffectBlocks][me-1]->SetProgramInput(InputId);
		}
		@catch (NSException *exception)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:exception.name];
			[alert runModal];
		}
	}
	else
	{
		@try
		{
			[s mMixEffectBlocks][me-1]->SetPreviewInput(InputId);
		}
		@catch (NSException *exception)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:exception.name];
			[alert runModal];
		}
	}
}

bool stringIsNumber(NSString * str)
{
	NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
	return [str rangeOfCharacterFromSet:notDigits].location == NSNotFound;
}

NSArray *mapObjectsUsingBlock(NSArray *array, id (^block)(id obj, NSUInteger idx)) {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addObject:block(obj, idx)];
    }];
    return result;
}

// address will start with a forward slash
void sendFeedbackMessage(Switcher *s, NSString *address, OSCValue* val) {
	// If a switcher nickname is set, they probably have multiple switchers connected
	// and are thus using nicknames, so include nickname in the feedback address
	if (s.nickname && s.nickname.length > 0)
		address = [NSString stringWithFormat:@"/atem/%@%@", s.nickname, address];
	else
		address = [NSString stringWithFormat:@"/atem%@", address];
	
	OSCMessage *msg = [OSCMessage createWithAddress:address];
	[msg addValue:val];
	[s.outPort sendThisMessage:msg];
	
	[s logMessage:[NSString stringWithFormat:@"Sending feedback message: %@  %@", address, val]];
}

// address will start with a forward slash
void sendFeedbackMessage(Switcher *s, NSString *address, OSCValue* val, int me) {
	// If there are multiple mix effect blocks on this switcher, include the block number in the feedback string
	if ([s mMixEffectBlocks].size() > 1)
	{
		sendFeedbackMessage(s, [NSString stringWithFormat:@"/me/%d%@", me, address], val);
		
		// If the first me, send message with no /me for backward compatability
		if (me == 1)
			sendFeedbackMessage(s, address, val);
	}
	else
		sendFeedbackMessage(s, address, val);
}
