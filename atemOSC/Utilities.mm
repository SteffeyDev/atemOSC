//
//  Utilities.cpp
//  AtemOSC
//
//  Created by Peter Steffey on 11/4/17.
//

#include "Utilities.h"
#import "AppDelegate.h"

bool isMacroValid(uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	bool isValid;
	if ([appDel mMacroPool])
	{
		result = [appDel mMacroPool]->IsValid(index, &isValid);
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

bool runMacroAtIndex(uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	if ([appDel mMacroControl])
	{
		if (!isMacroValid(index))
		{
			[appDel logMessage:[NSString stringWithFormat:@"Could not run the Macro at index %d because it is not valid.", index]];
			return NO;
		}
		
		result = [appDel mMacroControl]->Run(index);
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

bool stopRunningMacro()
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	if ([appDel mMacroControl])
	{
		result = [appDel mMacroControl]->StopRunning();
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

uint32_t getMaxNumberOfMacros()
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	uint32_t maxNumberOfMacros = 0;
	if ([appDel mMacroPool])
	{
		if (S_OK == [appDel mMacroPool]->GetMaxCount(&maxNumberOfMacros))
			return maxNumberOfMacros;
		else
			[appDel logMessage:@"Could not get max the number of Macros available."];
	}
	return maxNumberOfMacros;
}

NSString* getNameOfMacro(uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	NSString *name = @"";
	result = [appDel mMacroPool]->GetName(index, (CFStringRef*)&name);
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

NSString* getDescriptionOfMacro(uint32_t index)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	HRESULT result;
	NSString *description = @"";
	result = [appDel mMacroPool]->GetDescription(index, (CFStringRef*)&description);
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


void activateChannel(int channel, bool program)
{
	AppDelegate * appDel = static_cast<AppDelegate *>([[NSApplication sharedApplication] delegate]);
	BMDSwitcherInputId InputId = channel;
	if (program) {
		@try
		{
			[appDel mMixEffectBlock]->SetInt(bmdSwitcherMixEffectBlockPropertyIdProgramInput, InputId);
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
			[appDel mMixEffectBlock]->SetInt(bmdSwitcherMixEffectBlockPropertyIdPreviewInput, InputId);
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
