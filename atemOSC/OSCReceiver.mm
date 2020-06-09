#import "OSCReceiver.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation OSCReceiver

@synthesize endpointMap;
@synthesize validators;

- (instancetype) initWithDelegate:(AppDelegate *) delegate
{
	self = [super init];
	appDel = delegate;
	
	endpointMap = [[NSMutableDictionary alloc] init];
	validators = [[NSMutableDictionary alloc] init];
	
	NSLog(@"Setting up validators");
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		if ([appDel mMixEffectBlock])
			return true;
		[appDel logMessage:@"No mix effect block"];
		return false;
	} copy] forKey:@"/atem/transition"];

	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (key > 0 && key <= [appDel dsk].size())
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"DSK %d is not available on your switcher, valid DSK values are 1 - %lu", key, [appDel dsk].size()]];
		return false;
	} copy] forKey:@"/atem/dsk"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		NSString *address = [d objectForKey:@"address"];
		
		if (![appDel switcherTransitionParameters])
		{
			[appDel logMessage:@"No switcher transition parameters"];
			return false;
		}
		
		// Normal USK
		if (key > 0 && key <= [appDel keyers].size())
			return true;
		
		// Background
		if (key == 0 && [address containsString:@"tie"])
			return true;
		
		[appDel logMessage:[NSString stringWithFormat:@"USK %d is not available on your switcher, valid USK values are 1 - %lu", key, [appDel keyers].size()]];
		return false;
	} copy] forKey:@"/atem/usk"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int number = [[d objectForKey:@"<number>"] intValue];
		if ([appDel mHyperdecks].count(number-1) > 0)
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Hyperdeck %d is not available on your switcher, valid Hyperdecks are 1 - %lu", number, [appDel mHyperdecks].size()]];
		return false;
	} copy] forKey:@"/atem/hyperdeck"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int number = [[d objectForKey:@"<number>"] intValue];
		if ([appDel mAudioInputs].count(number) > 0)
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Invalid input %d. Please choose a valid audio input number from the list in Help > OSC addresses.", number]];
		return false;
	} copy] forKey:@"/atem/audio/input"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		if ([appDel mAudioMixer])
			return true;
		[appDel logMessage:@"No audio mixer"];
		return false;
	} copy] forKey:@"/atem/audio/output"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int number = [[d objectForKey:@"<number>"] intValue];
		if ([appDel mFairlightAudioSources].count(number) > 0)
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Invalid source %d. Please choose a valid Fairlight audio source number from the list in Help > OSC addresses.", number]];
		return false;
	} copy] forKey:@"/atem/fairlight-audio/source"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		if ([appDel mFairlightAudioMixer])
			return true;
		[appDel logMessage:@"No Fairlight audio mixer"];
		return false;
	} copy] forKey:@"/atem/fairlight-audio/output"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];

		if (![appDel mMediaPool])
		{
			[appDel logMessage:@"No media pool\n"];
			return false;
		}
		
		if ([appDel mMediaPlayers].size() < mplayer || mplayer < 0)
		{
			[appDel logMessage:[NSString stringWithFormat:@"No media player %d", mplayer]];
			return false;
		}
		return true;
	} copy] forKey:@"/atem/mplayer"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];

		if (![appDel mSuperSource])
		{
			[appDel logMessage:@"No super source"];
			return false;
		}
		
		if ([appDel mSuperSourceBoxes].size() < key)
		{
			[appDel logMessage:[NSString stringWithFormat:@"No super source box %d", key]];
			return false;
		}
		
		return true;
	} copy] forKey:@"/atem/supersource"];
	
	[validators setObject:[^bool(NSDictionary *d, OSCValue *v) {
		int auxToChange = [[d objectForKey:@"<key>"] intValue];
		if (auxToChange > 0 && auxToChange-1 < [appDel mSwitcherInputAuxList].size())
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Aux number %d not available on your switcher", auxToChange]];
		return false;
	} copy] forKey:@"/atem/aux"];
	
	
	
	NSLog(@"Setting up endpoints");
	
	[self addEndpoint:@"/atem/send-status" handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel sendStatus];
	}];
	
	[self addEndpoint:@"/atem/send-status/mix-effect-block" handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mMixEffectBlockMonitor]->sendStatus();
	}];
	
	[self addEndpoint:@"/atem/preview" valueType: OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		activateChannel([v intValue], false);
	}];
	
	[self addEndpoint:@"/atem/program" valueType: OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		activateChannel([v intValue], true);
	}];
	
	[self addEndpoint:@"/atem/transition/bar" valueType: OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		if ([appDel mMixEffectBlockMonitor]->mMoveSliderDownwards)
			[appDel mMixEffectBlock]->SetTransitionPosition([v floatValue]);
		else
			[appDel mMixEffectBlock]->SetTransitionPosition(1.0-[v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/transition/cut" handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mMixEffectBlock]->PerformCut();
	}];
	
	[self addEndpoint:@"/atem/transition/auto" handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mMixEffectBlock]->PerformAutoTransition();
	}];
	
	[self addEndpoint:@"/atem/transition/ftb" handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mMixEffectBlock]->PerformFadeToBlack();
	}];
	
	[self addEndpoint:@"/atem/transition/preview" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mMixEffectBlock]->SetPreviewTransition([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/transition/type" valueType:OSCValString handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		[appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters);
		
		if ([[v stringValue] isEqualToString:@"mix"])
			mTransitionParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleMix);
		else if ([[v stringValue] isEqualToString:@"dip"])
			mTransitionParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleDip);
		else if ([[v stringValue] isEqualToString:@"wipe"])
			mTransitionParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleWipe);
		else if ([[v stringValue] isEqualToString:@"sting"])
			mTransitionParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleStinger);
		else if ([[v stringValue] isEqualToString:@"dve"])
			mTransitionParameters->SetNextTransitionStyle(bmdSwitcherTransitionStyleDVE);
	}];
	
	[self addEndpoint:@"/atem/transition/rate" label:@"Set rate for selected transition type (mix, dip, wipe, or DVE)" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		[appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters);
		BMDSwitcherTransitionStyle style=NULL;
		mTransitionParameters->GetNextTransitionStyle(&style);
		
		IBMDSwitcherTransitionMixParameters* mTransitionMixParameters=NULL;
		IBMDSwitcherTransitionDipParameters* mTransitionDipParameters=NULL;
		IBMDSwitcherTransitionWipeParameters* mTransitionWipeParameters=NULL;
		IBMDSwitcherTransitionDVEParameters* mTransitionDVEParameters=NULL;

		switch (style) {
			case bmdSwitcherTransitionStyleMix:
				if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionMixParameters, (void**)&mTransitionMixParameters)))
					mTransitionMixParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleDip:
				if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionDipParameters)))
					mTransitionDipParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleWipe:
				if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionWipeParameters)))
					mTransitionWipeParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleDVE:
				if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionDVEParameters, (void**)&mTransitionDVEParameters)))
					mTransitionDVEParameters->SetRate([v floatValue]);
				break;
		}
	}];
	
	[self addEndpoint:@"/atem/transition/mix/rate" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionMixParameters* mTransitionMixParameters=NULL;
		if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionMixParameters, (void**)&mTransitionMixParameters)))
			mTransitionMixParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/transition/dip/rate" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionDipParameters* mTransitionDipParameters=NULL;
		if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionDipParameters)))
			mTransitionDipParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/transition/wipe/rate" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionWipeParameters* mTransitionWipeParameters=NULL;
		if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionWipeParameters, (void**)&mTransitionWipeParameters)))
			mTransitionWipeParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/transition/dve/rate" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		IBMDSwitcherTransitionDVEParameters* mTransitionDVEParameters=NULL;
		if (SUCCEEDED([appDel mMixEffectBlock]->QueryInterface(IID_IBMDSwitcherTransitionDVEParameters, (void**)&mTransitionDVEParameters)))
			mTransitionDVEParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/tie" label:@"Set USK<key> Tie" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[self changeTransitionSelection:key select:[v boolValue]];
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/tie/toggle" label: @"Toggle USK<key> Tie" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		uint32_t currentTransitionSelection;
		[appDel switcherTransitionParameters]->GetNextTransitionSelection(&currentTransitionSelection);
		
		uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
		uint32_t requestedTransitionSelection = transitionSelections[key];
		
		[self changeTransitionSelection:key select:!((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/tie/set-next" label:@"Set Next-Transition State for USK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isOnAir;
		[appDel keyers][key-1]->GetOnAir(&isOnAir);
		[self changeTransitionSelection:key select:([v boolValue] != isOnAir)];
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/on-air" label:@"Set USK<key> On Air" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel keyers][key-1]->SetOnAir([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/on-air/toggle" label:@"Toggle USK<key> On Air" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool onAir;
		[appDel keyers][key-1]->GetOnAir(&onAir);
		[appDel keyers][key-1]->SetOnAir(!onAir);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/source/fill" label:@"Set Fill Source for USK<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel keyers][key-1]->SetInputFill([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/source/cut" label:@"Set Cut Source for USK<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel keyers][key-1]->SetInputCut([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/type" label:@"Set USK<key> Type" valueType:OSCValString handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if ([[v stringValue] isEqualToString:@"luma"])
			[appDel keyers][key-1]->SetType(bmdSwitcherKeyTypeLuma);
		else if ([[v stringValue] isEqualToString:@"chroma"])
			[appDel keyers][key-1]->SetType(bmdSwitcherKeyTypeChroma);
		else if ([[v stringValue] isEqualToString:@"pattern"])
			[appDel keyers][key-1]->SetType(bmdSwitcherKeyTypePattern);
		else if ([[v stringValue] isEqualToString:@"dve"])
			[appDel keyers][key-1]->SetType(bmdSwitcherKeyTypeDVE);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/luma/pre-multiplied" label:@"Set Pre-Multiplied Luma Parameter for USK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key])
			lumaParams->SetPreMultiplied([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/luma/clip" label:@"Set Clip Luma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key])
			lumaParams->SetClip([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/luma/gain" label:@"Set Gain Luma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key])
			lumaParams->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/luma/inverse" label:@"Set Inverse Luma Parameter for USK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key])
			lumaParams->SetInverse([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/chroma/hue" label:@"Set Hue Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key])
			chromaParams->SetHue([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/chroma/gain" label:@"Set Gain Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key])
			chromaParams->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/chroma/y-suppress" label:@"Set Y-Suppress Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key])
			chromaParams->SetYSuppress([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/chroma/lift" label:@"Set Lift Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key])
			chromaParams->SetLift([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/chroma/narrow" label:@"Set Narrow Chroma Parameter for USK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key])
			chromaParams->SetNarrow([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/enabled" label:@"Set Border Enabled DVE Parameter for USK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderEnabled([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-width-inner" label:@"Set Border Inner Width DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderWidthIn([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-width-outer" label:@"Set Border Outer Width DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderWidthOut([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-softness-inner" label:@"Set Border Inner Softness DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderSoftnessIn([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-softness-outer" label:@"Set Border Outer Softness DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderSoftnessOut([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-opacity" label:@"Set Border Opacity DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderOpacity([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-hue" label:@"Set Border Hue DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderHue([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-saturation" label:@"Set Border Saturation DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderSaturation([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/usk/<key>/dve/border-luma" label:@"Set Border Luma DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key])
			dveParams->SetBorderLuma([v floatValue]);
	}];
	
	
	[self addEndpoint:@"/atem/dsk/<key>/tie" label:@"Set DSK<key> Tie" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[appDel dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [appDel dsk][key-1]->SetTie([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/tie/toggle" label:@"Toggle DSK<key> Tie" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTied, isTransitioning;
		[appDel dsk][key-1]->GetTie(&isTied);
		[appDel dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [appDel dsk][key-1]->SetTie(!isTied);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/tie/set-next" label:@"Set Next-Transition State for DSK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning, isOnAir;
		[appDel dsk][key-1]->IsTransitioning(&isTransitioning);
		[appDel dsk][key-1]->GetOnAir(&isOnAir);
		if (!isTransitioning) [appDel dsk][key-1]->SetTie([v boolValue] != isOnAir);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/on-air"  label:@"Set DSK<key> On Air" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[appDel dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [appDel dsk][key-1]->SetOnAir([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/on-air/toggle" label:@"Toggle DSK<key> On Air" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isLive, isTransitioning;
		[appDel dsk][key-1]->GetOnAir(&isLive);
		[appDel dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [appDel dsk][key-1]->SetOnAir(!isLive);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/on-air/auto" label:@"Auto-Transistion DSK<key>" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[appDel dsk][key-1]->IsAutoTransitioning(&isTransitioning);
		if (!isTransitioning) [appDel dsk][key-1]->PerformAutoTransition();
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/rate" label:@"Set Rate for DSK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetRate([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/source/fill" label:@"Set Fill Source for DSK<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetInputFill([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/source/cut" label:@"Set Cut Source for DSK<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetInputCut([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/clip" label:@"Set Clip Level for DSK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetClip([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/gain" label:@"Set Gain Level for DSK<key>" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/rate" label:@"Set Rate for DSK<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetRate([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/inverse" label:@"Set Inverse Parameter for DSK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetInverse([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/dsk/<key>/pre-multiplied" label:@"Set Pre-multiplied Parameter for DSK<key>" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel dsk][key-1]->SetPreMultiplied([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/mplayer/<player>/clip" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];
		[appDel mMediaPlayers][mplayer-1]->SetSource(bmdSwitcherMediaPlayerSourceTypeClip, [v intValue]-1);
	}];
	
	[self addEndpoint:@"/atem/mplayer/<player>/still" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];
		[appDel mMediaPlayers][mplayer-1]->SetSource(bmdSwitcherMediaPlayerSourceTypeStill, [v intValue]-1);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/enabled" label:@"Set Box <key> enabled" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetEnabled([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/source" label:@"Set Box <key> Input Source" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetInputSource([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/x" label:@"Set Box <key> X Position" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetPositionX([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/y" label:@"Set Box <key> Y Position" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetPositionY([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/size" label:@"Set Box <key> Size" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetSize([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/cropped" label:@"Set Box <key> Crop Enabled" valueType:OSCValBool handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetCropped([v boolValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/crop-top" label:@"Set Box <key> Crop Top Amount" valueType: OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetCropTop([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/crop-bottom" label:@"Set Box <key> Crop Bottom Amount" valueType: OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetCropBottom([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/crop-left" label:@"Set Box <key> Crop Left Amount" valueType: OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetCropLeft([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/crop-right" label:@"Set Box <key> Crop Right Amount" valueType: OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->SetCropRight([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/supersource/box/<key>/crop-reset" label:@"Reset box <key> crop" handler:^void(NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[appDel mSuperSourceBoxes][key-1]->ResetCrop();
	}];
	
	[self addEndpoint:@"/atem/macros/stop" label:@"Stop the currently active Macro (if any)" handler:^void(NSDictionary *d, OSCValue *v) {
		stopRunningMacro();
	}];
	
	[self addEndpoint:@"/atem/macros/max-number" label:@"Get the Maximum Number of Macros" handler:^void(NSDictionary *d, OSCValue *v) {
		uint32_t value = getMaxNumberOfMacros();
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/max-number"];
		[newMsg addInt:(int)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/atem/macros/<index>/run" label:@"Run the Macro at <index>" handler:^void(NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		int value = runMacroAtIndex(macroIndex); // Try to run the valid Macro
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/run"];
		[newMsg addInt:(int)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/atem/macros/<index>/name" label:@"Get the Name of a Macro" handler:^void(NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		NSString *value = getNameOfMacro(macroIndex);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/name"];
		[newMsg addString:(NSString *)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/atem/macros/<index>/description" label:@"Get the Description of a Macro" handler:^void(NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		NSString *value = getDescriptionOfMacro(macroIndex);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/description"];
		[newMsg addString:(NSString *)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/atem/macros/<index>/is-valid" label:@"Get whether the Macro at <index> is valid" handler:^void(NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		int value = isMacroValid(macroIndex) ? 1 : 0;
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/is-valid"];
		[newMsg addInt:(int)value];
		[[appDel outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/atem/aux/<key>" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		int auxToChange = [[d objectForKey:@"<key>"] intValue];
		BMDSwitcherInputId inputId = [v intValue];
		[appDel mSwitcherInputAuxList][auxToChange-1]->SetInputSource(inputId);
	}];
	
	[self addEndpoint:@"/atem/audio/input/<number>/gain" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mAudioInputs][inputNumber]->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/audio/input/<number>/balance" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mAudioInputs][inputNumber]->SetBalance([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/audio/output/gain" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mAudioMixer]->SetProgramOutGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/audio/output/balance" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mAudioMixer]->SetProgramOutBalance([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/fairlight-audio/source/<number>/gain" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherFairlightAudioSourceId sourceNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mFairlightAudioSources][sourceNumber]->SetFaderGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/fairlight-audio/source/<number>/pan" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherFairlightAudioSourceId sourceNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mFairlightAudioSources][sourceNumber]->SetPan([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/fairlight-audio/output/gain" valueType:OSCValFloat handler:^void(NSDictionary *d, OSCValue *v) {
		[appDel mFairlightAudioMixer]->SetMasterOutFaderGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/play" label:@"HyperDeck <number> Play" handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->Play();
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/stop" label:@"HyperDeck <number> Stop" handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->Stop();
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/record" label:@"HyperDeck <number> Record" handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->Record();
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/shuttle" label:@"HyperDeck <number> Shuttle" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->Shuttle([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/jog" label:@"HyperDeck <number> Jog" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->Jog([v intValue]);
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/clip" label:@"HyperDeck <number> Select Clip" valueType:OSCValInt handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[appDel mHyperdecks][hyperdeckNumber-1]->SetCurrentClip([v intValue]-1);
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/clip-time" label:@"HyperDeck <number> Set Clip Time" valueType:OSCValString handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[self setHyperDeckTime:hyperdeckNumber-1 time:[v stringValue] clip:YES];
	}];
	
	[self addEndpoint:@"/atem/hyperdeck/<number>/timeline-time" label:@"HyperDeck <number> Set Timeline Time" valueType:OSCValString handler:^void(NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[self setHyperDeckTime:hyperdeckNumber-1 time:[v stringValue] clip:NO];
	}];
	
	// Recursively build the tree from the list
	// This allows for O(1) calls to find the handler for the address instead of O(n)
	for (OSCEndpoint *endpoint in [appDel endpoints])
		[self buildMapLevel:endpointMap endpoint:endpoint index:0];

	// Turn on for debugging
	//[self printLevel:endpointMap index:0];
	
	return self;
}

// For debugging purposes
- (void) printLevel:(NSMutableDictionary *)level index:(int)index
{
	if ([level isKindOfClass:[OSCEndpoint class]])
		return;
	
	for (NSString *key in [level allKeys])
	{
		NSLog(@"%@%@", [@"" stringByPaddingToLength:index*2 withString: @" " startingAtIndex:0], key);
		if ([level objectForKey:key] != nil)
			[self printLevel:[level objectForKey:key] index:index+1];
	}
}

// Recursive function to build the endpoint tree from the endpoint list
// Tree is just nested dictionaries that correspond to each component in the OSC address
- (void) buildMapLevel:(NSMutableDictionary *)level endpoint:(OSCEndpoint *)endpoint index:(int)index
{
	NSMutableArray *addressComponents = [NSMutableArray arrayWithArray:[[endpoint addressTemplate] componentsSeparatedByString:@"/"]];
	[addressComponents removeObjectAtIndex:0]; // Remove empty string
	NSString *key = [addressComponents objectAtIndex:index];
	
	// Create new dictionaries as needed
	if ([level objectForKey:key] == nil)
		[level setObject:[[NSMutableDictionary alloc] init] forKey:key];
	
	if (index == [addressComponents count] - 1)
		[[level objectForKey:key] setObject:endpoint forKey:@"handler"];
	else
		[self buildMapLevel:[level objectForKey:key] endpoint:endpoint index:index+1];
}

// Helper function for cleaner syntax when add endpoints (see examples above)
- (void) addEndpoint:(NSString *)addressTemplate label:(NSString*)label valueType:(OSCValueType)valueType handler:(void (^)(NSDictionary *, OSCValue *))handler
{
	OSCEndpoint *endpoint = [[OSCEndpoint alloc] init];
	endpoint.addressTemplate = addressTemplate;
	endpoint.handler = handler;
	endpoint.valueType = valueType;
	endpoint.label = label;
	[[appDel endpoints] addObject: endpoint];
}
- (void) addEndpoint:(NSString *)addressTemplate valueType:(OSCValueType)valueType handler:(void (^)(NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:nil valueType:valueType handler:handler];
}

// Makes valueType an optional parameter
- (void) addEndpoint:(NSString *)addressTemplate handler:(void (^)(NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:nil valueType:OSCValNil handler:handler];
}
- (void) addEndpoint:(NSString *)addressTemplate label:(NSString*)label handler:(void (^)(NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:label valueType:OSCValNil handler:handler];
}

- (OSCEndpoint *) findEndpointForAddress:(NSString *)address whileUpdatingArgs:(NSMutableDictionary *)args andSettingFinalLevel:(NSMutableDictionary *)finalLevel
{
	NSMutableArray<NSString *> *addressComponents = [NSMutableArray arrayWithArray:[address componentsSeparatedByString:@"/"]];
	[addressComponents removeObjectAtIndex:0]; // remove empty string
	
	NSMutableDictionary *currentLevel = endpointMap;
	
	// Go down tree of possible endpoints until one is found that matches
	// Add paramaterized values as we go (ones that look like <something>)
	for (int i = 0; i < [addressComponents count]; i++)
	{
		NSString *method = addressComponents[i];
		
		// Match directly if possible
		if ([currentLevel objectForKey:method] != nil)
			currentLevel = [currentLevel objectForKey:method];
		// Otherwise, this is a variable or invalid method
		else
		{
			// In case this is a variable in the address string, look for address templates that accept variables at this location
			NSString *paramPlaceholder = nil;
			for (NSString *option in [currentLevel allKeys])
			{
				if ([option hasPrefix:@"<"])
				{
					paramPlaceholder = option;

					// Set args to pass this to the handler function
					if (stringIsNumber(method))
						[args setObject:[NSNumber numberWithInt:[method intValue]] forKey:option];
					else
						[args setObject:method forKey:option];
				}
			}
			
			// If found, set the level and continue
			if ([currentLevel objectForKey:paramPlaceholder] != nil)
				currentLevel = [currentLevel objectForKey:paramPlaceholder];
			// If we didn't find any available endpoints that accept, leave the loop and error out
			else
			{
				[finalLevel addEntriesFromDictionary:currentLevel];
				return nil;
			}
		}
	}
	
	[finalLevel addEntriesFromDictionary:currentLevel];
	if ([currentLevel objectForKey:@"handler"] != nil)
		return [currentLevel objectForKey:@"handler"];
	
	return nil;
}

// Starting at any point in the tree, recursively returns all child endpoints
// This is useful for showing contextual help menus when they type invalue commands
- (NSArray<OSCEndpoint *> *) getEndpointsForNode:(NSMutableDictionary *)node
{
	if (node == nil)
		return [[NSArray<OSCEndpoint *> alloc] init];
	
	NSMutableArray *endpoints = [[NSMutableArray alloc] init];
	for (NSMutableDictionary *object in [node allValues])
	{
		if ([object isKindOfClass:[OSCEndpoint class]])
			[endpoints addObject:object];
		else
			[endpoints addObjectsFromArray:[self getEndpointsForNode:object]];
	}
	
	return endpoints;
}

- (void) receivedOSCMessage:(OSCMessage *)m
{
	[appDel logMessage:[NSString stringWithFormat:@"Received OSC message: %@\tValue: %@", [m address], [m value]]];
	
	if (![appDel isConnectedToATEM])
		return [appDel logMessage:[NSString stringWithFormat:@"Cannot process command %@ because no switcher connected", [m address]]];
	
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	[args setValue:[m address] forKey:@"address"];

	NSMutableDictionary *finalLevel = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *finalLevelSecondTry = [[NSMutableDictionary alloc] init];
	OSCValue *value = [m value];

	// First check normal address and values
	OSCEndpoint *endpoint = [self findEndpointForAddress:[m address] whileUpdatingArgs:args andSettingFinalLevel:finalLevel];
	
	// Then try passing the last component of the address as the value and see if that matches any better
	// This would be common with TouchOSC, for example passing /transition/type/mix 1.0 instead of /transition/type mix
	if (endpoint == nil)
	{
		// In TouchOSC specifically, it will send a float value of 1.0 on button press and 0.0 on button release
		// This ignores the button release message to prevent duplicate calls
		if ([[m value] type] == OSCValFloat && [[m value] floatValue] == 0.0)
			return;
		
		NSMutableArray *componentArray = [[NSMutableArray alloc] initWithArray:[[m address] componentsSeparatedByString:@"/"]];
		if (stringIsNumber([componentArray lastObject]))
			value = [OSCValue createWithInt:[[componentArray lastObject] intValue]];
		else
			value = [OSCValue createWithString:[componentArray lastObject]];
		[componentArray removeLastObject];
		NSString *modifiedAddress = [componentArray componentsJoinedByString:@"/"];
		[args removeAllObjects];
		endpoint = [self findEndpointForAddress:modifiedAddress whileUpdatingArgs:args andSettingFinalLevel:finalLevelSecondTry];
	}
	
	if (endpoint != nil)
	{
		NSLog(@"Found OSCEndpoint for address: %@", [m address]);
		
		if (value == nil && endpoint.valueType != OSCValNil)
			return [appDel logMessage:[NSString stringWithFormat:@"Value required for %@, but no value given", [m address]]];
		
		OSCValueType neededType = endpoint.valueType;
		OSCValueType actualType = [value type];
		if (actualType != neededType)
		{
			// Transform value if needed to match desired type
			// This is needed for compatibility with TouchOSC mostly, which can only send floats that need to be converted to ints and bools
			if (neededType == OSCValInt && actualType == OSCValFloat)
				value = [OSCValue createWithInt:(int)[[m value] floatValue]];
			else if (neededType == OSCValFloat && actualType == OSCValInt)
				value = [OSCValue createWithFloat:(float)[[m value] intValue]];
			else if (neededType == OSCValBool && actualType == OSCValFloat)
				value = [OSCValue createWithBool:[[m value] floatValue] == 1.0];
			else if (neededType == OSCValBool && actualType == OSCValInt)
				value = [OSCValue createWithBool:[[m value] intValue] == 1];
			else if (neededType == OSCValNil)
				[appDel logMessage:[NSString stringWithFormat:@"Unecessary value passed for %@, but running regardless", [m address]]];
			else
				return [appDel logMessage:[NSString stringWithFormat:@"Incorrect value type for %@", [m address]]];
		}
				
		// Pass validation if needed (relatively small number of validators should ensure this is performant)
		// Validation functions will print their own error messages, so we can just exit directly if they fail
		for (NSString *validatorKey in [validators allKeys])
			if ([[endpoint addressTemplate] hasPrefix:validatorKey] && ![validators objectForKey:validatorKey](args, value))
				return;
		
		// Call handler found for address with paramaterized arguments and value of matching type
		endpoint.handler(args, value);
	}
	
	else
	{
		// Given the last element we could match, show possible future elements that they might have meant
		if ([[finalLevel allKeys] count] > 0)
		{
			NSArray *possibleEndpoints = [self getEndpointsForNode:finalLevel];
			if ([possibleEndpoints count] < 15)
			{
				NSMutableArray *possibleAddresses = [[NSMutableArray alloc] init];
				for (OSCEndpoint *endpoint in possibleEndpoints)
					[possibleAddresses addObject:[endpoint addressTemplate]];

				return [appDel logMessage:[NSString stringWithFormat:@"OSC endpoint not implemented for %@, maybe you meant to call one of these methods: %@", [m address], [possibleAddresses componentsJoinedByString:@", "]]];
			}
		}
		
		[appDel logMessage:[NSString stringWithFormat:@"OSC endpoint not implemented for %@, refer to the help menu for a list of available addresses", [m address]]];
	}
}

- (IBMDSwitcherKeyLumaParameters *) getUSKLumaParams:(int)t
{
	IBMDSwitcherKey* key = [appDel keyers][t-1];
	IBMDSwitcherKeyLumaParameters* lumaParams;
	key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
	return lumaParams;
}

- (IBMDSwitcherKeyChromaParameters *) getUSKChromaParams:(int)t
{
	IBMDSwitcherKey* key = [appDel keyers][t-1];
	IBMDSwitcherKeyChromaParameters* chromaParams;
	key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
	return chromaParams;
}

- (IBMDSwitcherKeyDVEParameters *) getUSKDVEParams:(int)t
{
	IBMDSwitcherKey* key = [appDel keyers][t-1];
	IBMDSwitcherKeyDVEParameters* dveParams;
	key->QueryInterface(IID_IBMDSwitcherKeyDVEParameters, (void**)&dveParams);
	return dveParams;
}

- (void) changeTransitionSelection:(int)t select:(bool) select
{
	if ([appDel switcherTransitionParameters] == nil)
	{
		return;
	}
	
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

- (void) setHyperDeckTime:(long long)hyperdeckId time:(NSString *)timeString clip:(BOOL)clipTime
{
	NSArray *timeComponents = [timeString componentsSeparatedByString:@":"];
	uint16_t hour = 0;
	uint8_t minute = 0, second = 0, frame = 0;
	if (timeComponents.count == 1 && stringIsNumber(timeComponents[0]))
		second = [timeComponents[0] intValue];
	else if (timeComponents.count == 2 && stringIsNumber(timeComponents[0]) && stringIsNumber(timeComponents[1]))
	{
		minute = [timeComponents[0] intValue];
		second = [timeComponents[1] intValue];
	}
	else if (timeComponents.count == 3 && stringIsNumber(timeComponents[0]) && stringIsNumber(timeComponents[1]) && stringIsNumber(timeComponents[2]))
	{
		hour = [timeComponents[0] intValue];
		minute = [timeComponents[1] intValue];
		second = [timeComponents[2] intValue];
	}
	else
		[appDel logMessage:[NSString stringWithFormat:@"Invalid time '%@'. You must specify a time in the format HH:MM:SS (e.g. 00:00:05)", timeString]];
	
	HRESULT status;
	if (clipTime)
		status = [appDel mHyperdecks][hyperdeckId]->SetCurrentClipTime(hour, minute, second, frame);
	else
		status = [appDel mHyperdecks][hyperdeckId]->SetCurrentTimelineTime(hour, minute, second, frame);
	
	if (status != S_OK)
		[appDel logMessage:[NSString stringWithFormat:@"Could not seek to time '%@'. Make sure the time is valid and not past the end of the clip/timeline.", timeString]];
}

@end
