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
						[appDel mMixEffectBlock]->SetTransitionPosition([m calculateFloatValue]);
					else
						[appDel mMixEffectBlock]->SetTransitionPosition(1.0-[m calculateFloatValue]);
				}
				
				else if ([[address objectAtIndex:3] isEqualToString:@"cut"])
					[appDel mMixEffectBlock]->PerformCut();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"auto"])
					[appDel mMixEffectBlock]->PerformAutoTransition();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"ftb"])
					[appDel mMixEffectBlock]->PerformFadeToBlack();
				
				else if ([[address objectAtIndex:3] isEqualToString:@"preview"])
					[appDel mMixEffectBlock]->SetPreviewTransition((int)[m calculateFloatValue]);
				
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
			
			else if ([[address objectAtIndex:2] isEqualToString:@"usk"] && [address count] > 4)
			{
				if (stringIsNumber([address objectAtIndex:3]))
				{
					int t = [[address objectAtIndex:3] intValue];
					
					if ([[address objectAtIndex:4] isEqualToString:@"tie"])
					{
						// Toggle tie
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"toggle"])
						{
							uint32_t currentTransitionSelection;
							[appDel switcherTransitionParameters]->GetNextTransitionSelection(&currentTransitionSelection);
							
							uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
							uint32_t requestedTransitionSelection = transitionSelections[t];
							
							[self changeTransitionSelection:t select:!((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
						}
						
						// Set for state after next transition
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"set-next"])
						{
							bool value = [[m value] floatValue] != 0.0;
							
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								bool isOnAir;
								key->GetOnAir(&isOnAir);
								
								[self changeTransitionSelection:t select:(value != isOnAir)];
							}
						}
						
						// Set tie
						else if ([address count] == 5)
						{
							bool value = [[m value] floatValue] != 0.0;
							[self changeTransitionSelection:t select:value];
						}
						
						else
							[appDel logMessage:@"You must specify a usk tie command of 'toggle' or 'set-next', or send a value to set the tie on or off"];
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"on-air"])
					{
						// Cut toggle on-air
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"toggle"])
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								bool onAir;
								key->GetOnAir(&onAir);
								key->SetOnAir(!onAir);
							}
						}
						
						// Force set on-air
						else if ([address count] == 5)
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								bool value = [[m value] floatValue] != 0.0;
								key->SetOnAir(value);
							}
						}
						
						else
							[appDel logMessage:@"You must specify a usk on-air command of 'toggle' or send a value to cut the usk on or off air"];
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"source"])
					{
						// Get/Set Fill Source
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"fill"])
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								if ([m valueCount] > 0)
								{
									BMDSwitcherInputId inputId = [[m value] intValue];
									key->SetInputFill(inputId);
								}
							}
						}
						
						// Get/Set Key (cut) Source
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"cut"])
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								if ([m valueCount] > 0)
								{
									BMDSwitcherInputId inputId = [[m value] intValue];
									key->SetInputCut(inputId);
								}
							}
						}
						
						else
							[appDel logMessage:@"You must specify a usk source command of 'fill' or 'cut'"];
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"type"])
					{
						if (([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"luma"]) || [[[m value] stringValue] isEqualToString: @"luma"])
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								key->SetType(bmdSwitcherKeyTypeLuma);
							}
						}
						else if (([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"chroma"]) || ([m valueCount] > 0 && [[[m value] stringValue] isEqualToString: @"chroma"]))
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								key->SetType(bmdSwitcherKeyTypeChroma);
							}
						}
						else if (([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"pattern"]) || ([m valueCount] > 0 && [[[m value] stringValue] isEqualToString: @"pattern"]))
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								key->SetType(bmdSwitcherKeyTypePattern);
							}
						}
						else if (([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"dve"]) || ([m valueCount] > 0 && [[[m value] stringValue] isEqualToString: @"dve"]))
						{
							if (IBMDSwitcherKey* key = [self getUSK:t])
							{
								key->SetType(bmdSwitcherKeyTypeDVE);
							}
						}
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"luma"])
					{
						// Get/Set PreMultiplied
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"pre-multiplied"])
						{
							if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:t])
							{
								if ([m valueCount] > 0)
								{
									lumaParams->SetPreMultiplied([[m value] boolValue]);
								}
							}
						}
						
						// Get/Set Clip
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"clip"])
						{
							if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:t])
							{
								if ([m valueCount] > 0)
								{
									lumaParams->SetClip([[m value] floatValue]);
								}
							}
						}
						
						// Get/Set Gain
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"gain"])
						{
							if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:t])
							{
								if ([m valueCount] > 0)
								{
									lumaParams->SetGain([[m value] floatValue]);
								}
							}
						}
						
						// Get/Set Inverse
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"inverse"])
						{
							if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:t])
							{
								if ([m valueCount] > 0)
								{
									lumaParams->SetInverse([[m value] boolValue]);
								}
							}
						}
						
						else
							[appDel logMessage:@"You must specify a usk luma command of 'pre-multiplied', 'clip', 'gain', or 'inverse'"];
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"chroma"])
					{
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"hue"])
						{
							if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:t])
							{
								if ([m valueCount] > 0)
								{
									chromaParams->SetHue([[m value] floatValue]);
								}
							}
						}
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"gain"])
						{
							if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:t])
							{
								if ([m valueCount] > 0)
								{
									chromaParams->SetGain([[m value] floatValue]);
								}
							}
						}
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"y-suppress"])
						{
							if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:t])
							{
								if ([m valueCount] > 0)
								{
									chromaParams->SetYSuppress([[m value] floatValue]);
								}
							}
						}
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"lift"])
						{
							if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:t])
							{
								if ([m valueCount] > 0)
								{
									chromaParams->SetLift([[m value] floatValue]);
								}
							}
						}
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"narrow"])
						{
							if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:t])
							{
								if ([m valueCount] > 0)
								{
									chromaParams->SetNarrow([[m value] boolValue]);
								}
							}
						}
						
						else
							[appDel logMessage:@"You must specify a usk chroma command of 'hue', 'gain', 'y-suppress', 'lift', or 'narrow'"];
					}
					
					else
						[appDel logMessage:@"You must specify a usk command of 'tie', 'on-air', 'type', 'source', 'chroma', or 'luma'"];
				}
				
				else
					[appDel logMessage:[NSString stringWithFormat:@"You must specify a usk between 0 and %lu", [appDel keyers].size()]];
			}

			// Deprecated
			else if ([[address objectAtIndex:2] isEqualToString:@"set-nextusk"])
			{
				int t = [[address objectAtIndex:3] intValue];
				bool value = [m calculateFloatValue] != 0.0;
				
				if (IBMDSwitcherKey* key = [self getUSK:t])
				{
					bool isOnAir;
					key->GetOnAir(&isOnAir);
					
					[self changeTransitionSelection:t select:(value != isOnAir)];
				}
			}
			
			// Deprecated
			else if ([[address objectAtIndex:2] isEqualToString:@"nextusk"])
			{
				int t = [[address objectAtIndex:3] intValue];
				bool value = [m calculateFloatValue] != 0.0;
				[self changeTransitionSelection:t select:value];
			}
			
			// Deprecated
			else if ([[address objectAtIndex:2] isEqualToString:@"usk"])
			{
				IBMDSwitcherKey* key = [self getUSK:[[address objectAtIndex:3] intValue]];
				if (key && [m calculateFloatValue] != 0.0)
				{
					bool onAir;
					key->GetOnAir(&onAir);
					key->SetOnAir(!onAir);
				}
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"dsk"])
			{
				// Deprecated
				if ([[address objectAtIndex:3] isEqualToString:@"set-tie"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [m calculateFloatValue] != 0.0;
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetTie(value);
					}
				}
				
				// Deprecated
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
				
				// Deprecated
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
				
				// Deprecated
				else if ([[address objectAtIndex:3] isEqualToString:@"on-air"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [m calculateFloatValue] != 0.0;
						bool isTransitioning;
						key->IsTransitioning(&isTransitioning);
						if (!isTransitioning) key->SetOnAir(value);
					}
				}
				
				// Deprecated
				else if ([[address objectAtIndex:3] isEqualToString:@"set-next"])
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:4] intValue]])
					{
						bool value = [m calculateFloatValue] != 0.0;
						bool isTransitioning, isOnAir;
						key->IsTransitioning(&isTransitioning);
						key->GetOnAir(&isOnAir);
						if (!isTransitioning) key->SetTie(value != isOnAir);
					}
				}
				
				// Deprecated
				else if ([address count] == 4 && stringIsNumber([address objectAtIndex:3]))
				{
					if (IBMDSwitcherDownstreamKey* key = [self getDSK:[[address objectAtIndex:3] intValue]])
					{
						bool isTransitioning;
						key->IsAutoTransitioning(&isTransitioning);
						if (!isTransitioning) key->PerformAutoTransition();
					}
				}
				
				else if ([address count] > 4 && stringIsNumber([address objectAtIndex:3]))
				{
					int t = [[address objectAtIndex:3] intValue];
					
					if ([[address objectAtIndex:4] isEqualToString:@"tie"])
					{
						// Toggle tie
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"toggle"])
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool isTied;
								key->GetTie(&isTied);
								bool isTransitioning;
								key->IsTransitioning(&isTransitioning);
								if (!isTransitioning) key->SetTie(!isTied);
							}
						}
						
						// Set for state after next transition
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"set-next"])
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool value = [m calculateFloatValue] != 0.0;
								bool isTransitioning, isOnAir;
								key->IsTransitioning(&isTransitioning);
								key->GetOnAir(&isOnAir);
								if (!isTransitioning) key->SetTie(value != isOnAir);
							}
						}
						
						// Set tie
						else if ([address count] == 5)
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool value = [m calculateFloatValue] != 0.0;
								bool isTransitioning;
								key->IsTransitioning(&isTransitioning);
								if (!isTransitioning) key->SetTie(value);
							}
						}
						
						else
							[appDel logMessage:@"You must specify a dsk tie command of 'toggle' or 'set-next', or send a value to set the tie on or off"];
					}
					
					else if ([[address objectAtIndex:4] isEqualToString:@"on-air"])
					{
						// Cut toggle on-air
						if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"toggle"])
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool isLive;
								key->GetOnAir(&isLive);
								bool isTransitioning;
								key->IsTransitioning(&isTransitioning);
								if (!isTransitioning) key->SetOnAir(!isLive);
							}
						}
						
						// Auto on-air
						else if ([address count] == 6 && [[address objectAtIndex:5] isEqualToString:@"auto"])
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool isTransitioning;
								key->IsAutoTransitioning(&isTransitioning);
								if (!isTransitioning) key->PerformAutoTransition();
							}
						}
						
						// Set on-air
						else if ([address count] == 5)
						{
							if (IBMDSwitcherDownstreamKey* key = [self getDSK:t])
							{
								bool value = [m calculateFloatValue] != 0.0;
								bool isTransitioning;
								key->IsTransitioning(&isTransitioning);
								if (!isTransitioning) key->SetOnAir(value);
							}
						}
						
						else
							[appDel logMessage:@"You must specify a dsk on-air command of 'toggle' or 'auto', or send a value to cut the dsk on or off air"];
					}
					
					else
						[appDel logMessage:@"You must specify a dsk command of 'tie' or 'on-air'"];
				}
				
				else
					[appDel logMessage:[NSString stringWithFormat:@"You must specify a dsk between 1 and %lu", [appDel dsk].size()]];
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
				int source = [m calculateFloatValue];
				[self handleAuxSource:auxToChange channel:source];
			}
			
			else if ([[address objectAtIndex:2] isEqualToString:@"audio"] && [address count] > 3)
			{
				if ([[address objectAtIndex:3] isEqualToString:@"input"])
				{
					if (stringIsNumber([address objectAtIndex:4]))
					{
						BMDSwitcherAudioInputId inputNumber = [[address objectAtIndex:4] intValue];
						if ([appDel mAudioInputs].count(inputNumber) > 0)
						{
							if ([[address objectAtIndex:5] isEqualToString:@"gain"])
								[appDel mAudioInputs][inputNumber]->SetGain([m calculateFloatValue]);

							else if ([[address objectAtIndex:5] isEqualToString:@"balance"])
								[appDel mAudioInputs][inputNumber]->SetBalance([m calculateFloatValue]);

							else
								[appDel logMessage:[NSString stringWithFormat:@"Invalid option '%@'. You must specify an audio input option of 'gain' or 'balance'", [address objectAtIndex:5]]];
						}

						else
							[appDel logMessage:[NSString stringWithFormat:@"Invalid input %lld. Please choose a valid audio input number from the list in Help > OSC addresses.", inputNumber]];
					}

					else
						[appDel logMessage:[NSString stringWithFormat:@"Invalid input %@. The address following input/ must be a number", [address objectAtIndex:4]]];
				}

				else if ([[address objectAtIndex:3] isEqualToString:@"output"])
				{
					if ([[address objectAtIndex:4] isEqualToString:@"gain"])
						[appDel mAudioMixer]->SetProgramOutGain([m calculateFloatValue]);
					
					else if ([[address objectAtIndex:4] isEqualToString:@"balance"])
						[appDel mAudioMixer]->SetProgramOutBalance([m calculateFloatValue]);
					
					else
						[appDel logMessage:[NSString stringWithFormat:@"Invalid option '%@'. You must specify an audio output option of 'gain' or 'balance'", [address objectAtIndex:4]]];
				}
				
				else
					[appDel logMessage:[NSString stringWithFormat:@"Invalid command '%@'. You must specify an audio command of 'input' or 'output'", [address objectAtIndex:3]]];
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

- (IBMDSwitcherKeyLumaParameters *) getUSKLumaParams:(int)t
{
	if (t<=[appDel keyers].size())
	{
		IBMDSwitcherKey* key = [appDel keyers][t-1];
		IBMDSwitcherKeyLumaParameters* lumaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		return lumaParams;
	}
	return nullptr;
}

- (IBMDSwitcherKeyChromaParameters *) getUSKChromaParams:(int)t
{
	if (t<=[appDel keyers].size())
	{
		IBMDSwitcherKey* key = [appDel keyers][t-1];
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		return chromaParams;
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
        [appDel mSuperSourceBorder]->SetBorderEnabled(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"border-outer"])
    {
        float value = [m calculateFloatValue];
        [appDel mSuperSourceBorder]->SetBorderWidthOut(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"border-inner"])
    {
        float value = [m calculateFloatValue];
        [appDel mSuperSourceBorder]->SetBorderWidthIn(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"border-hue"])
    {
        float value = [m calculateFloatValue];
        [appDel mSuperSourceBorder]->SetBorderHue(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"border-saturations"])
    {
        float value = [m calculateFloatValue];
        [appDel mSuperSourceBorder]->SetBorderSaturation(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"border-luminescence"])
    {
        float value = [m calculateFloatValue];
        [appDel mSuperSourceBorder]->SetBorderLuma(value);
    }

    else if ([[address objectAtIndex:3] isEqualToString:@"box"])
	{
		[self handleSuperSourceBox:m address:address];
	}
	
	else
		[appDel logMessage:@"You must specify a super-source command of 'box'"];
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
		bool value = [m calculateFloatValue] != 0.0;
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
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetPositionX(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"y"])
	{
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetPositionY(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"size"])
	{
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetSize(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"cropped"])
	{
		bool value = [m calculateFloatValue] != 0.0;
		[appDel mSuperSourceBoxes][box]->SetCropped(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-top"])
	{
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetCropTop(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-bottom"])
	{
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetCropBottom(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-left"])
	{
		float value = [m calculateFloatValue];
		[appDel mSuperSourceBoxes][box]->SetCropLeft(value);
	}
	
	else if ([[address objectAtIndex:5] isEqualToString:@"crop-right"])
	{
		float value = [m calculateFloatValue];
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
