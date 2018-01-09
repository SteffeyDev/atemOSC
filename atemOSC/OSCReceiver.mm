#import "OSCReceiver.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation OSCReceiver

- (instancetype) initWithDelegate:(AppDelegate *) delegate
{
	self = [super init];
	appDel = delegate;
	return self;
}

- (void) receivedOSCMessage:(OSCMessage *)m
{
	[appDel logMessage:[NSString stringWithFormat:@"Received OSC message: %@\tValue: %@", [m address], [m value]]];
	if ([appDel isConnectedToATEM]) { //Do nothing if not connected
		NSArray *address = [[m address] componentsSeparatedByString:@"/"];
		
		if ([[address objectAtIndex:1] isEqualToString:@"atem"])
		{
			if ([[address objectAtIndex:2] isEqualToString:@"send-status"])
				[appDel sendStatus];
			
			else if ([[address objectAtIndex:2] isEqualToString:@"preview"] || [[address objectAtIndex:2] isEqualToString:@"program"])
				activateChannel([[address objectAtIndex:3] intValue], [[address objectAtIndex:2] isEqualToString:@"program"]);
			
			else if ([[address objectAtIndex:2] isEqualToString:@"transition"])
			{
				if ([[address objectAtIndex:3] isEqualToString:@"bar"])
				{
					if ([appDel mMixEffectBlockMonitor]->mMoveSliderDownwards)
						[appDel mMixEffectBlock]->SetFloat(bmdSwitcherMixEffectBlockPropertyIdTransitionPosition, [[m valueAtIndex:0] floatValue]);
					else
						[appDel mMixEffectBlock]->SetFloat(bmdSwitcherMixEffectBlockPropertyIdTransitionPosition, 1.0-[[m valueAtIndex:0] floatValue]);
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"cut"] && [[m valueAtIndex:0] floatValue]==1.0)
					[appDel mMixEffectBlock]->PerformCut();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"auto"] && [[m valueAtIndex:0] floatValue]==1.0)
					[appDel mMixEffectBlock]->PerformAutoTransition();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"ftb"])
					[appDel mMixEffectBlock]->PerformFadeToBlack();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"set-type"])
				{
					
					HRESULT result;
					NSString *style = [address objectAtIndex:4];
					REFIID transitionStyleID = IID_IBMDSwitcherTransitionParameters;
					IBMDSwitcherTransitionParameters* mTransitionStyleParameters=NULL;
					result = [appDel mMixEffectBlock]->QueryInterface(transitionStyleID, (void**)&mTransitionStyleParameters);
					if (SUCCEEDED(result))
					{
						if ([style isEqualToString:@"mix"])
							mTransitionStyleParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleMix);
						
						else if ([style isEqualToString:@"dip"])
							mTransitionStyleParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleDip);
						
						else if ([style isEqualToString:@"wipe"])
							mTransitionStyleParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleWipe);
						
						else if ([style isEqualToString:@"sting"])
							mTransitionStyleParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleStinger);
						
						else if ([style isEqualToString:@"dve"])
							mTransitionStyleParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleDVE);
						
						else
							[appDel logMessage:@"You must specify a transition type of 'mix', 'dip', 'wipe', 'sting', or 'dve'"];
					}
				}
				
				else
					[appDel logMessage:@"You must specify a transition action of 'bar', 'cut', 'auto', 'ftb', or 'set-type"];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"set-nextusk"])
			{
				int t = [[address objectAtIndex:3] intValue];
				bool value = [[m value] floatValue] != 0.0;
				
				if (IBMDSwitcherKey* key = [self getUSK:t])
				{
					bool isOnAir;
					key->GetOnAir(&isOnAir);
					
					[self changeTransitionSelection:t select:(value != isOnAir)];
				}
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"nextusk"])
			{
				int t = [[address objectAtIndex:3] intValue];
				bool value = [[m value] floatValue] != 0.0;
				[self changeTransitionSelection:t select:value];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"usk"])
			{
				IBMDSwitcherKey* key = [self getUSK:[[address objectAtIndex:3] intValue]];
				if (key && [[m value] floatValue] != 0.0)
				{
					bool onAir;
					key->GetOnAir(&onAir);
					key->SetOnAir(!onAir);
					[appDel logMessage:[NSString stringWithFormat:@"dsk on %@", m]];
				}
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"dsk"])
			{
				if ([[address objectAtIndex:3] isEqualToString:@"set-tie"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [[m value] floatValue] != 0.0;
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetTie(value);
					}
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"tie"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool isTied;
						key->GetTie(&isTied);
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetTie(!isTied);
					}
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"toggle"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool isLive;
						key->GetOnAir(&isLive);
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetOnAir(!isLive);
					}
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"on-air"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [[m value] floatValue] != 0.0;
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetOnAir(value);
					}
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"set-next"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [[m value] floatValue] != 0.0;
						bool isTransitioning, isOnAir;
						key->IsTransitioning(&isTransitioning);
						key->GetOnAir(&isOnAir);
						if (!isTransitioning) key->SetTie(value != isOnAir);
					}
				}
				
				else if (stringIsNumber([address objectAtIndex:3]))
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:3] intValue]])
					{
						bool isTransitioning;
						key->IsAutoTransitioning(&isTransitioning);
						if (!isTransitioning) key->PerformAutoTransition();
					}
				}
				
				else
					[appDel logMessage:@"You must specify a dsk command of 'set-tie', 'tie', 'toggle', 'on-air', 'set-next', or send an integer value to toggle auto on-air"];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"mplayer"])
			{
				int mplayer = [[address objectAtIndex:3] intValue];
				NSString *type = [address objectAtIndex:4];
				int requestedValue = [[address objectAtIndex:5] intValue];
				BMDSwitcherMediaPlayerSourceType sourceType;
				
				// check we have the media pool
				if (![appDel mMediaPool])
				{
					[appDel logMessage:@"No media pool\n"];
					return;
				}
				
				if ([appDel mMediaPlayers].size() < mplayer || mplayer < 0)
				{
					[appDel logMessage:[NSString stringWithFormat:@"No media player %d", mplayer]];
					return;
				}
				
				if ([type isEqualToString:@"clip"])
				{
					sourceType = bmdSwitcherMediaPlayerSourceTypeClip;
				}
				else if ([type isEqualToString:@"still"])
				{
					sourceType = bmdSwitcherMediaPlayerSourceTypeStill;
				}
				else
				{
					[appDel logMessage:@"You must specify the Media type 'clip' or 'still'"];
					return;
				}
				// set media player source
				HRESULT result;
				result = [appDel mMediaPlayers][mplayer-1]->SetSource(sourceType, requestedValue-1);
				if (FAILED(result))
				{
					[appDel logMessage:[NSString stringWithFormat:@"Could not set media player %d source\n", mplayer]];
					return;
				}
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"supersource"])
			{
				[self handleSuperSource:m address:address];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"macros"])
			{
				[self handleMacros:m address:address];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"aux"])
			{
				int auxToChange = [[address objectAtIndex:3] intValue];
				int source = [[m value] floatValue];
				[self handleAuxSource:auxToChange channel:source];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"audio"] && [address count] > 3)
			{
				if ([[address objectAtIndex:3] isEqualToString:@"output"])
				{
					
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"input"])
				{
					if (stringIsNumber([address objectAtIndex:4]) && [[address objectAtIndex:4] intValue] < [appDel mAudioInputs].size())
					{
						if ([[address objectAtIndex:5] isEqualToString:@"gain"])
							[appDel mAudioInputs][[[address objectAtIndex:4] intValue]]->SetGain([[m value] doubleValue]);

						else if ([[address objectAtIndex:5] isEqualToString:@"balance"])
							[appDel mAudioInputs][[[address objectAtIndex:4] intValue]]->SetBalance([[m value] doubleValue]);
					}

					else
						[appDel logMessage:[NSString stringWithFormat:@"Please choose an audio input between 0 and %lu", [appDel mAudioInputs].size() - 1]];
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"mixer"])
				{
					
				}
				
				else
					[appDel logMessage:@"You must specify an audio command of 'input', 'output', or 'mixer'"];
			}
			
			else
				[appDel logMessage:[NSString stringWithFormat:@"Cannot handle command: %@\nYou can find a list of valid commands in the help menu", [m address]]];
		}
		else
			[appDel logMessage:[NSString stringWithFormat:@"Cannot handle command: %@\nYou can find a list of valid commands in the help menu", [m address]]];
	}
	else
		[appDel logMessage:[NSString stringWithFormat:@"Cannot process command %@ because no switcher connected", [m address]]];
}

- (IBMDSwitcherDownstreamKey *) getDSK:(int)t
{
	if (t<=[appDel dsk].size())
	{
		return [appDel dsk][t-1];
	}
	return nullptr;
}

- (IBMDSwitcherKey *) getUSK:(int)t
{
	if (t<=[appDel keyers].size())
	{
		return [appDel keyers][t-1];
	}
	return nullptr;
}

- (void) changeTransitionSelection:(int)t select:(bool) select
{
	uint32_t currentTransitionSelection;
	[appDel switcherTransitionParameters]->GetNextTransitionSelection(&currentTransitionSelection);
	
	uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
	uint32_t requestedTransitionSelection = transitionSelections[t];
	
	if (select)
	{
		[appDel switcherTransitionParameters]->SetNextTransitionSelection(currentTransitionSelection | requestedTransitionSelection);
	}
	else
	{
		// If we are attempting to deselect the only bit set, then default to setting TransitionSelectionBackground
		if ((currentTransitionSelection & ~requestedTransitionSelection) == 0)
			[appDel switcherTransitionParameters]->SetNextTransitionSelection(bmdSwitcherTransitionSelectionBackground);
		else
			[appDel switcherTransitionParameters]->SetNextTransitionSelection(currentTransitionSelection & ~requestedTransitionSelection);
	}
}

- (void) handleAuxSource:(int)auxToChange channel:(int)channel
{
	BMDSwitcherInputId inputId = channel;
	if (auxToChange-1 < [appDel mSwitcherInputAuxList].size())
		[appDel mSwitcherInputAuxList][auxToChange-1]->SetInputSource(inputId);
	else
		[appDel logMessage:[NSString stringWithFormat:@"Aux number %d not available on your switcher", channel]];
}

- (void) handleMacros:(OSCMessage *)m address:(NSArray*)address
{
	if (![appDel mMacroPool] || ![appDel mMacroControl])
	{
		// No Macro support
		OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
		[newMsg addInt:(int)0];
		[[appDel outPort] sendThisMessage:newMsg];
		return;
	}
	if ([[address objectAtIndex:3] isEqualToString:@"get-max-number"] || [[address objectAtIndex:3] isEqualToString:@"max-number"])
	{
		uint32_t value = getMaxNumberOfMacros();
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
		[newMsg addInt:(int)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}
	else if ([[address objectAtIndex:3] isEqualToString:@"stop"])
	{
		stopRunningMacro();
	}
	else
	{
		if (stringIsNumber([address objectAtIndex:3]))
		{
			int macroIndex = [[address objectAtIndex:3] intValue];
			if ([[address objectAtIndex:4] isEqualToString:@"name"])
			{
				NSString *value = getNameOfMacro(macroIndex);
				OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
				[newMsg addString:(NSString *)value];
				[[appDel outPort] sendThisMessage:newMsg];
			}
			
			else if ([[address objectAtIndex:4] isEqualToString:@"description"])
			{
				NSString *value = getDescriptionOfMacro(macroIndex);
				OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
				[newMsg addString:(NSString *)value];
				[[appDel outPort] sendThisMessage:newMsg];
			}
			
			else if ([[address objectAtIndex:4] isEqualToString:@"is-valid"])
			{
				int value = 0;
				if (isMacroValid(macroIndex))
				{
					value = 1;
				}
				OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
				[newMsg addInt:(int)value];
				[[appDel outPort] sendThisMessage:newMsg];
			}
			
			else if ([[address objectAtIndex:4] isEqualToString:@"run"])
			{
				int value = 0;
				if (isMacroValid(macroIndex))
				{
					// Try to run the valid Macro
					value = runMacroAtIndex(macroIndex);
				}
				OSCMessage *newMsg = [OSCMessage createWithAddress:[m address]];
				[newMsg addInt:(int)value];
				[[appDel outPort] sendThisMessage:newMsg];
			}
			
			else
				[appDel logMessage:[NSString stringWithFormat:@"You must specify a macro command of 'run', 'name', 'description', or 'is-valid' for the macro at index %d", macroIndex]];
		}
		else
			[appDel logMessage:@"You must specify a macro command of 'max-number', 'stop', or send the macro number you want to control as an integer"];
	}
}

- (void) handleSuperSource:(OSCMessage *)m address:(NSArray*)address
{
	if ([[address objectAtIndex:3] isEqualToString:@"border-enabled"])
	{
		bool value = [[address objectAtIndex:4] boolValue];
		[appDel mSuperSource]->SetBorderEnabled(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"border-outer"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSource]->SetBorderWidthOut(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"border-inner"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSource]->SetBorderWidthIn(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"border-hue"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSource]->SetBorderHue(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"border-saturations"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSource]->SetBorderSaturation(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"border-luminescence"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSource]->SetBorderLuma(value);
	}
	
	else if ([[address objectAtIndex:3] isEqualToString:@"box"])
	{
		[self handleSuperSourceBox:m address:address];
	}
	
	else
		[appDel logMessage:@"You must specify a super-source command of 'border-enabled', 'border-outer', 'border-inner', 'border-hue', 'border-saturations', 'border-luminescence', or 'box'"];
}

- (void) handleSuperSourceBox:(OSCMessage *)m address:(NSArray*)address
{
	int box = [[address objectAtIndex:4] intValue];
	
	// check we have the super source
	if (![appDel mSuperSource])
	{
		[appDel logMessage:@"No super source"];
		return;
	}
	
	if ([appDel mSuperSourceBoxes].size() < box)
	{
		[appDel logMessage:[NSString stringWithFormat:@"No super source box %d", box]];
		return;
	}
	
	// convert to value required for arrays
	box--;
	
	if ([[address objectAtIndex:5] isEqualToString:@"enabled"])
	{
		bool value = [[m value] floatValue] != 0.0;
		[appDel mSuperSourceBoxes][box]->SetEnabled(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"source"])
	{
		int value = [[m value] intValue];
		BMDSwitcherInputId InputId = value;
		[appDel mSuperSourceBoxes][box]->SetInputSource(InputId);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"x"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetPositionX(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"y"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetPositionY(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"size"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetSize(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"cropped"])
	{
		bool value = [[m value] floatValue] != 0.0;
		[appDel mSuperSourceBoxes][box]->SetCropped(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-top"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetCropTop(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-bottom"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetCropBottom(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-left"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetCropLeft(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-right"])
	{
		float value = [[m value] floatValue];
		[appDel mSuperSourceBoxes][box]->SetCropRight(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-reset"])
	{
		[appDel mSuperSourceBoxes][box]->ResetCrop();
	}
	
	else
		[appDel logMessage:@"You must specify a super-source box command of 'enabled', 'source', 'x', 'y', 'size', 'cropped', 'crop-top', 'crop-bottom', 'crop-left', 'crop-right', or 'crop-reset'"];
}

@end
