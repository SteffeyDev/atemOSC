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
	NSString *name = @"";
	result = [s mMacroPool]->GetName(index, (CFStringRef*)&name);
	switch (result)
	{
		case S_OK:
			return name;
		case E_INVALIDARG:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the name of the Macro at index %d because the index is invalid.", index]];
			break;
		case E_OUTOFMEMORY:
			[appDel logMessage:[NSString stringWithFormat:@"Insufficient memory to get the name of the Macro at index %d.", index]];
			break;
		default:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the name of the Macro at index %d.", index]];
	}
	return name;
}

NSString* getDescriptionOfMacro(Switcher *s, uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	NSString *description = @"";
	result = [s mMacroPool]->GetDescription(index, (CFStringRef*)&description);
	switch (result)
	{
		case S_OK:
			return description;
		case E_INVALIDARG:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the description of the Macro at index %d because the index is invalid.", index]];
			break;
		case E_OUTOFMEMORY:
			[appDel logMessage:[NSString stringWithFormat:@"Insufficient memory to get the description of the Macro at index %d.", index]];
			break;
		default:
			[appDel logMessage:[NSString stringWithFormat:@"Could not get the description of the Macro at index %d.", index]];
	}
	return description;
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
