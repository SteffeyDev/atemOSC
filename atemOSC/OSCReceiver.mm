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
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		if (me > 0 && me <= [s mMixEffectBlocks].size())
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"No mix effect block %d", me]];
		return false;
	} copy] forKey:@"/me"];

	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		if (key > 0 && key <= [s dsk].size())
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"DSK %d is not available on your switcher, valid DSK values are 1 - %lu", key, [s dsk].size()]];
		return false;
	} copy] forKey:@"/dsk"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		NSString *address = [d objectForKey:@"address"];

		// Normal USK
		if (key > 0 && key <= [s keyers][me-1].size())
			return true;
		
		// Background
		if (key == 0 && [address containsString:@"tie"])
			return true;
		
		[appDel logMessage:[NSString stringWithFormat:@"USK %d is not available on your switcher, valid USK values are 1 - %lu", key, [s keyers].size()]];
		return false;
	} copy] forKey:@"/me/<me>/usk"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int number = [[d objectForKey:@"<number>"] intValue];
		if ([s mHyperdecks].count(number-1) > 0)
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Hyperdeck %d is not available on your switcher, valid Hyperdecks are 1 - %lu", number, [s mHyperdecks].size()]];
		return false;
	} copy] forKey:@"/hyperdeck"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int number = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioInputs].count(number) > 0 || [s mFairlightAudioInputs].count(number) > 0)
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Invalid input %d. Please choose a valid audio input number from the list in the Addresses tab.", number]];
		return false;
	} copy] forKey:@"/audio/input"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		if ([s mAudioMixer] || [s mFairlightAudioMixer])
			return true;
		[appDel logMessage:@"No audio mixer"];
		return false;
	} copy] forKey:@"/audio/output"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];

		if (![s mMediaPool])
		{
			[appDel logMessage:@"No media pool\n"];
			return false;
		}
		
		if ([s mMediaPlayers].size() < mplayer || mplayer < 0)
		{
			[appDel logMessage:[NSString stringWithFormat:@"No media player %d", mplayer]];
			return false;
		}
		return true;
	} copy] forKey:@"/mplayer"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];

		if (![s mSuperSource])
		{
			[appDel logMessage:@"No super source"];
			return false;
		}
		
		if ([s mSuperSourceBoxes].size() < key)
		{
			[appDel logMessage:[NSString stringWithFormat:@"No super source box %d", key]];
			return false;
		}
		
		return true;
	} copy] forKey:@"/supersource"];
	
	[validators setObject:[^bool(Switcher *s, NSDictionary *d, OSCValue *v) {
		int auxToChange = [[d objectForKey:@"<key>"] intValue];
		if (auxToChange > 0 && auxToChange-1 < [s mSwitcherInputAuxList].size())
			return true;
		[appDel logMessage:[NSString stringWithFormat:@"Aux number %d not available on your switcher", auxToChange]];
		return false;
	} copy] forKey:@"/aux"];
	
	
	
	NSLog(@"Setting up endpoints");
	
	[self addEndpoint:@"/send-status" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		[s sendStatus];
	}];
	
	[self addEndpoint:@"/me/<me>/send-status" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		[s mMixEffectBlockMonitors][me-1]->sendStatus();
	}];
	
	[self addEndpoint:@"/me/<me>/preview" valueType: OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		activateChannel(s, me, [v intValue], false);
	}];
	
	[self addEndpoint:@"/me/<me>/program" valueType: OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		activateChannel(s, me, [v intValue], true);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/bar" valueType: OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		if ([s mMixEffectBlockMonitors][me-1]->mMoveSliderDownwards)
			[s mMixEffectBlocks][me-1]->SetTransitionPosition([v floatValue]);
		else
			[s mMixEffectBlocks][me-1]->SetTransitionPosition(1.0-[v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/cut" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		[s mMixEffectBlocks][me-1]->PerformCut();
	}];
	
	[self addEndpoint:@"/me/<me>/transition/auto" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		[s mMixEffectBlocks][me-1]->PerformAutoTransition();
	}];
	
	[self addEndpoint:@"/me/<me>/transition/ftb" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		[s mMixEffectBlocks][me-1]->PerformFadeToBlack();
	}];
	
	[self addEndpoint:@"/me/<me>/transition/preview" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		[s mMixEffectBlocks][me-1]->SetPreviewTransition([v boolValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/type" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		[s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters);
		
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
	
	[self addEndpoint:@"/me/<me>/transition/rate" label:@"Set rate for selected transition type (mix, dip, wipe, or DVE)" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		[s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters);
		BMDSwitcherTransitionStyle style=NULL;
		mTransitionParameters->GetNextTransitionStyle(&style);
		
		IBMDSwitcherTransitionMixParameters* mTransitionMixParameters=NULL;
		IBMDSwitcherTransitionDipParameters* mTransitionDipParameters=NULL;
		IBMDSwitcherTransitionWipeParameters* mTransitionWipeParameters=NULL;
		IBMDSwitcherTransitionDVEParameters* mTransitionDVEParameters=NULL;

		switch (style) {
			case bmdSwitcherTransitionStyleMix:
				if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionMixParameters, (void**)&mTransitionMixParameters)))
					mTransitionMixParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleDip:
				if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionDipParameters)))
					mTransitionDipParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleWipe:
				if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionWipeParameters)))
					mTransitionWipeParameters->SetRate([v floatValue]);
				break;
			case bmdSwitcherTransitionStyleDVE:
				if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionDVEParameters, (void**)&mTransitionDVEParameters)))
					mTransitionDVEParameters->SetRate([v floatValue]);
				break;
		}
	}];
	
	[self addEndpoint:@"/me/<me>/transition/mix/rate" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionMixParameters* mTransitionMixParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionMixParameters, (void**)&mTransitionMixParameters)))
			mTransitionMixParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/dip/rate" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionDipParameters* mTransitionDipParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void**)&mTransitionDipParameters)))
			mTransitionDipParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/wipe/rate" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionWipeParameters* mTransitionWipeParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionWipeParameters, (void**)&mTransitionWipeParameters)))
			mTransitionWipeParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/transition/dve/rate" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionDVEParameters* mTransitionDVEParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionDVEParameters, (void**)&mTransitionDVEParameters)))
			mTransitionDVEParameters->SetRate([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/tie" label:@"Set USK<key> Tie" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters)))
		{
			int key = [[d objectForKey:@"<key>"] intValue];
			[self changeTransitionSelection:key select:[v boolValue] forTransitionParameters:mTransitionParameters];
		}
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/tie/toggle" label: @"Toggle USK<key> Tie" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters)))
		{
			int key = [[d objectForKey:@"<key>"] intValue];
			uint32_t currentTransitionSelection;
			mTransitionParameters->GetNextTransitionSelection(&currentTransitionSelection);
			
			uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
			uint32_t requestedTransitionSelection = transitionSelections[key];
			
			[self changeTransitionSelection:key select:!((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection) forTransitionParameters:mTransitionParameters];
		}
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/tie/set-next" label:@"Set Next-Transition State for USK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters)))
		{
			int key = [[d objectForKey:@"<key>"] intValue];
			bool isOnAir;
			[s keyers][me-1][key-1]->GetOnAir(&isOnAir);
			[self changeTransitionSelection:key select:([v boolValue] != isOnAir) forTransitionParameters:mTransitionParameters];
		}
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/on-air" label:@"Set USK<key> On Air" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
		if (SUCCEEDED([s mMixEffectBlocks][me-1]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters)))
		{
			int key = [[d objectForKey:@"<key>"] intValue];
			[s keyers][me-1][key-1]->SetOnAir([v boolValue]);
		}
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/on-air/toggle" label:@"Toggle USK<key> On Air" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		bool onAir;
		[s keyers][me-1][key-1]->GetOnAir(&onAir);
		[s keyers][me-1][key-1]->SetOnAir(!onAir);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/source/fill" label:@"Set Fill Source for USK<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		[s keyers][me-1][key-1]->SetInputFill([v intValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/source/cut" label:@"Set Cut Source for USK<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		[s keyers][me-1][key-1]->SetInputCut([v intValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/type" label:@"Set USK<key> Type" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if ([[v stringValue] isEqualToString:@"luma"])
			[s keyers][me-1][key-1]->SetType(bmdSwitcherKeyTypeLuma);
		else if ([[v stringValue] isEqualToString:@"chroma"])
			[s keyers][me-1][key-1]->SetType(bmdSwitcherKeyTypeChroma);
		else if ([[v stringValue] isEqualToString:@"pattern"])
			[s keyers][me-1][key-1]->SetType(bmdSwitcherKeyTypePattern);
		else if ([[v stringValue] isEqualToString:@"dve"])
			[s keyers][me-1][key-1]->SetType(bmdSwitcherKeyTypeDVE);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/luma/pre-multiplied" label:@"Set Pre-Multiplied Luma Parameter for USK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key forSwitcher:s andME:me])
			lumaParams->SetPreMultiplied([v boolValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/luma/clip" label:@"Set Clip Luma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key forSwitcher:s andME:me])
			lumaParams->SetClip([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/luma/gain" label:@"Set Gain Luma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key forSwitcher:s andME:me])
			lumaParams->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/luma/inverse" label:@"Set Inverse Luma Parameter for USK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyLumaParameters* lumaParams = [self getUSKLumaParams:key forSwitcher:s andME:me])
			lumaParams->SetInverse([v boolValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/chroma/hue" label:@"Set Hue Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key forSwitcher:s andME:me])
			chromaParams->SetHue([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/chroma/gain" label:@"Set Gain Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key forSwitcher:s andME:me])
			chromaParams->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/chroma/y-suppress" label:@"Set Y-Suppress Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key forSwitcher:s andME:me])
			chromaParams->SetYSuppress([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/chroma/lift" label:@"Set Lift Chroma Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key forSwitcher:s andME:me])
			chromaParams->SetLift([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/chroma/narrow" label:@"Set Narrow Chroma Parameter for USK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyChromaParameters* chromaParams = [self getUSKChromaParams:key forSwitcher:s andME:me])
			chromaParams->SetNarrow([v boolValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/enabled" label:@"Set Border Enabled DVE Parameter for USK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderEnabled([v boolValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-width-inner" label:@"Set Border Inner Width DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderWidthIn([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-width-outer" label:@"Set Border Outer Width DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderWidthOut([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-softness-inner" label:@"Set Border Inner Softness DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderSoftnessIn([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-softness-outer" label:@"Set Border Outer Softness DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderSoftnessOut([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-opacity" label:@"Set Border Opacity DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderOpacity([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-hue" label:@"Set Border Hue DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderHue([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-saturation" label:@"Set Border Saturation DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderSaturation([v floatValue]);
	}];
	
	[self addEndpoint:@"/me/<me>/usk/<key>/dve/border-luma" label:@"Set Border Luma DVE Parameter for USK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int me = [[d objectForKey:@"<me>"] intValue];
		int key = [[d objectForKey:@"<key>"] intValue];
		if (IBMDSwitcherKeyDVEParameters* dveParams = [self getUSKDVEParams:key forSwitcher:s andME:me])
			dveParams->SetBorderLuma([v floatValue]);
	}];
	
	
	[self addEndpoint:@"/dsk/<key>/tie" label:@"Set DSK<key> Tie" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[s dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [s dsk][key-1]->SetTie([v boolValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/tie/toggle" label:@"Toggle DSK<key> Tie" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTied, isTransitioning;
		[s dsk][key-1]->GetTie(&isTied);
		[s dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [s dsk][key-1]->SetTie(!isTied);
	}];
	
	[self addEndpoint:@"/dsk/<key>/tie/set-next" label:@"Set Next-Transition State for DSK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning, isOnAir;
		[s dsk][key-1]->IsTransitioning(&isTransitioning);
		[s dsk][key-1]->GetOnAir(&isOnAir);
		if (!isTransitioning) [s dsk][key-1]->SetTie([v boolValue] != isOnAir);
	}];
	
	[self addEndpoint:@"/dsk/<key>/on-air"  label:@"Set DSK<key> On Air" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[s dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [s dsk][key-1]->SetOnAir([v boolValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/on-air/toggle" label:@"Toggle DSK<key> On Air" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isLive, isTransitioning;
		[s dsk][key-1]->GetOnAir(&isLive);
		[s dsk][key-1]->IsTransitioning(&isTransitioning);
		if (!isTransitioning) [s dsk][key-1]->SetOnAir(!isLive);
	}];
	
	[self addEndpoint:@"/dsk/<key>/on-air/auto" label:@"Auto-Transistion DSK<key>" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		bool isTransitioning;
		[s dsk][key-1]->IsAutoTransitioning(&isTransitioning);
		if (!isTransitioning) [s dsk][key-1]->PerformAutoTransition();
	}];
	
	[self addEndpoint:@"/dsk/<key>/rate" label:@"Set Rate for DSK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetRate([v intValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/source/fill" label:@"Set Fill Source for DSK<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetInputFill([v intValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/source/cut" label:@"Set Cut Source for DSK<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetInputCut([v intValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/clip" label:@"Set Clip Level for DSK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetClip([v floatValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/gain" label:@"Set Gain Level for DSK<key>" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/rate" label:@"Set Rate for DSK<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetRate([v intValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/inverse" label:@"Set Inverse Parameter for DSK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetInverse([v boolValue]);
	}];
	
	[self addEndpoint:@"/dsk/<key>/pre-multiplied" label:@"Set Pre-multiplied Parameter for DSK<key>" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s dsk][key-1]->SetPreMultiplied([v boolValue]);
	}];
	
	[self addEndpoint:@"/mplayer/<player>/clip" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];
		[s mMediaPlayers][mplayer-1]->SetSource(bmdSwitcherMediaPlayerSourceTypeClip, [v intValue]-1);
	}];
	
	[self addEndpoint:@"/mplayer/<player>/still" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int mplayer = [[d objectForKey:@"<player>"] intValue];
		[s mMediaPlayers][mplayer-1]->SetSource(bmdSwitcherMediaPlayerSourceTypeStill, [v intValue]-1);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/enabled" label:@"Set Box <key> enabled" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetEnabled([v boolValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/source" label:@"Set Box <key> Input Source" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetInputSource([v intValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/x" label:@"Set Box <key> X Position" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetPositionX([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/y" label:@"Set Box <key> Y Position" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetPositionY([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/size" label:@"Set Box <key> Size" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetSize([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/cropped" label:@"Set Box <key> Crop Enabled" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetCropped([v boolValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/crop-top" label:@"Set Box <key> Crop Top Amount" valueType: OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetCropTop([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/crop-bottom" label:@"Set Box <key> Crop Bottom Amount" valueType: OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetCropBottom([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/crop-left" label:@"Set Box <key> Crop Left Amount" valueType: OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetCropLeft([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/crop-right" label:@"Set Box <key> Crop Right Amount" valueType: OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->SetCropRight([v floatValue]);
	}];
	
	[self addEndpoint:@"/supersource/box/<key>/crop-reset" label:@"Reset box <key> crop" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int key = [[d objectForKey:@"<key>"] intValue];
		[s mSuperSourceBoxes][key-1]->ResetCrop();
	}];
	
	[self addEndpoint:@"/macros/stop" label:@"Stop the currently active Macro (if any)" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		stopRunningMacro(s);
	}];
	
	[self addEndpoint:@"/macros/max-number" label:@"Get the Maximum Number of Macros" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		uint32_t value = getMaxNumberOfMacros(s);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/max-number"];
		[newMsg addInt:(int)value];
		[[s outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/macros/<index>/run" label:@"Run the Macro at <index>" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		int value = runMacroAtIndex(s, macroIndex); // Try to run the valid Macro
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/run"];
		[newMsg addInt:(int)value];
		[[s outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/macros/<index>/name" label:@"Get the Name of a Macro" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		NSString *value = getNameOfMacro(s, macroIndex);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/name"];
		[newMsg addString:(NSString *)value];
		[[s outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/macros/<index>/description" label:@"Get the Description of a Macro" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		NSString *value = getDescriptionOfMacro(s, macroIndex);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/description"];
		[newMsg addString:(NSString *)value];
		[[s outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/macros/<index>/is-valid" label:@"Get whether the Macro at <index> is valid" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int macroIndex = [[d objectForKey:@"<index>"] intValue];
		int value = isMacroValid(s, macroIndex) ? 1 : 0;
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/<index>/is-valid"];
		[newMsg addInt:(int)value];
		[[s outPort] sendThisMessage:newMsg];
	}];
	
	[self addEndpoint:@"/aux/<key>" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		int auxToChange = [[d objectForKey:@"<key>"] intValue];
		BMDSwitcherInputId inputId = [v intValue];
		[s mSwitcherInputAuxList][auxToChange-1]->SetInputSource(inputId);
	}];
	
	[self addEndpoint:@"/audio/input/<number>/gain" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioMixer])
			[s mAudioInputs][inputNumber]->SetGain([v floatValue]);
		else if ([s mFairlightAudioMixer])
		{
			// Set gain on all sources (only one in stereo mode or two in dual mono mode)
			std::map<BMDSwitcherFairlightAudioSourceId, IBMDSwitcherFairlightAudioSource*> sources = [s mFairlightAudioSources][inputNumber];
			for (auto const& it : sources)
				it.second->SetFaderGain([v floatValue]);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<input>/left/gain" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<input>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /left/gain is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			[s mFairlightAudioSources][inputNumber].begin()->second->SetFaderGain([v floatValue]);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<input>/right/gain" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<input>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /right/gain is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			[s mFairlightAudioSources][inputNumber].end()->second->SetFaderGain([v floatValue]);
		}
	}];
		
	[self addEndpoint:@"/audio/input/<number>/balance" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioMixer])
			[s mAudioInputs][inputNumber]->SetBalance([v floatValue]);
		else
		{
			// Set balance on all sources (only one in stereo mode or two in dual mono mode)
			std::map<BMDSwitcherFairlightAudioSourceId, IBMDSwitcherFairlightAudioSource*> sources = [s mFairlightAudioSources][inputNumber];
			for (auto const& it : sources)
				it.second->SetPan([v floatValue]);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<input>/left/balance" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<input>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /left/balance is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			[s mFairlightAudioSources][inputNumber].begin()->second->SetPan([v floatValue]);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<input>/right/balance" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<input>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /right/balance is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			[s mFairlightAudioSources][inputNumber].end()->second->SetPan([v floatValue]);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<number>/mix" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioMixer])
		{
			if ([[v stringValue] isEqualToString:@"afv"])
				[s mAudioInputs][inputNumber]->SetMixOption(bmdSwitcherAudioMixOptionAudioFollowVideo);
			else if ([[v stringValue] isEqualToString:@"on"])
				[s mAudioInputs][inputNumber]->SetMixOption(bmdSwitcherAudioMixOptionOn);
			else if ([[v stringValue] isEqualToString:@"off"])
				[s mAudioInputs][inputNumber]->SetMixOption(bmdSwitcherAudioMixOptionOff);
		}
		else if ([s mFairlightAudioMixer])
		{
			// Set gain on all sources (only one in stereo mode or two in dual mono mode)
			std::map<BMDSwitcherFairlightAudioSourceId, IBMDSwitcherFairlightAudioSource*> sources = [s mFairlightAudioSources][inputNumber];
			for (auto const& it : sources)
			{
				if ([[v stringValue] isEqualToString:@"afv"])
					it.second->SetMixOption(bmdSwitcherFairlightAudioMixOptionAudioFollowVideo);
				else if ([[v stringValue] isEqualToString:@"on"])
					it.second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOn);
				else if ([[v stringValue] isEqualToString:@"off"])
					it.second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOff);
			}
		}
	}];
	
	[self addEndpoint:@"/audio/input/<number>/left/mix" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /left/mix is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			if ([[v stringValue] isEqualToString:@"afv"])
				[s mFairlightAudioSources][inputNumber].begin()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionAudioFollowVideo);
			else if ([[v stringValue] isEqualToString:@"on"])
				[s mFairlightAudioSources][inputNumber].begin()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOn);
			else if ([[v stringValue] isEqualToString:@"off"])
				[s mFairlightAudioSources][inputNumber].begin()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOff);
		}
	}];
	
	[self addEndpoint:@"/audio/input/<number>/right/mix" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherAudioInputId inputNumber = [[d objectForKey:@"<number>"] intValue];
		if ([s mAudioMixer])
			[appDel logMessage:@"Address /right/mix is not supported for this audio mixer"];
		else if ([s mFairlightAudioMixer])
		{
			if ([[v stringValue] isEqualToString:@"afv"])
				[s mFairlightAudioSources][inputNumber].end()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionAudioFollowVideo);
			else if ([[v stringValue] isEqualToString:@"on"])
				[s mFairlightAudioSources][inputNumber].end()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOn);
			else if ([[v stringValue] isEqualToString:@"off"])
				[s mFairlightAudioSources][inputNumber].end()->second->SetMixOption(bmdSwitcherFairlightAudioMixOptionOff);
		}
	}];
	
	[self addEndpoint:@"/audio/output/gain" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		if ([s mAudioMixer])
			[s mAudioMixer]->SetProgramOutGain([v floatValue]);
		else if ([s mFairlightAudioMixer])
			[s mFairlightAudioMixer]->SetMasterOutFaderGain([v floatValue]);
	}];
	
	[self addEndpoint:@"/audio/output/balance" valueType:OSCValFloat handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		if ([s mAudioMixer])
			[s mAudioMixer]->SetProgramOutBalance([v floatValue]);
		else if ([s mFairlightAudioMixer])
			[appDel logMessage:@"Output balance not supported for Fairlight audio mixer"];
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/play" label:@"HyperDeck <number> Play" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->Play();
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/stop" label:@"HyperDeck <number> Stop" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->Stop();
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/record" label:@"HyperDeck <number> Record" handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->Record();
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/shuttle" label:@"HyperDeck <number> Shuttle" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->Shuttle([v intValue]);
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/jog" label:@"HyperDeck <number> Jog" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->Jog([v intValue]);
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/clip" label:@"HyperDeck <number> Select Clip" valueType:OSCValInt handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->SetCurrentClip([v intValue]-1);
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/clip-time" label:@"HyperDeck <number> Set Clip Time" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[self setHyperDeckTime:hyperdeckNumber-1 time:[v stringValue] clip:YES forSwitcher:s];
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/timeline-time" label:@"HyperDeck <number> Set Timeline Time" valueType:OSCValString handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[self setHyperDeckTime:hyperdeckNumber-1 time:[v stringValue] clip:NO forSwitcher:s];
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/single-clip" label:@"HyperDeck <number> Set Single Clip Playback" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->SetSingleClipPlayback([v boolValue]);
	}];
	
	[self addEndpoint:@"/hyperdeck/<number>/loop" label:@"HyperDeck <number> Set Looped Playback" valueType:OSCValBool handler:^void(Switcher *s, NSDictionary *d, OSCValue *v) {
		BMDSwitcherHyperDeckId hyperdeckNumber = [[d objectForKey:@"<number>"] intValue];
		[s mHyperdecks][hyperdeckNumber-1]->SetLoopedPlayback([v boolValue]);
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
- (void) addEndpoint:(NSString *)addressTemplate label:(NSString*)label valueType:(OSCValueType)valueType handler:(void (^)(Switcher *s, NSDictionary *, OSCValue *))handler
{
	OSCEndpoint *endpoint = [[OSCEndpoint alloc] init];
	endpoint.addressTemplate = addressTemplate;
	endpoint.handler = handler;
	endpoint.valueType = valueType;
	endpoint.label = label;
	[[appDel endpoints] addObject: endpoint];
}
- (void) addEndpoint:(NSString *)addressTemplate valueType:(OSCValueType)valueType handler:(void (^)(Switcher *s, NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:nil valueType:valueType handler:handler];
}

// Makes valueType an optional parameter
- (void) addEndpoint:(NSString *)addressTemplate handler:(void (^)(Switcher *s, NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:nil valueType:OSCValNil handler:handler];
}
- (void) addEndpoint:(NSString *)addressTemplate label:(NSString*)label handler:(void (^)(Switcher *s, NSDictionary *, OSCValue *))handler
{
	[self addEndpoint:addressTemplate label:label valueType:OSCValNil handler:handler];
}

- (OSCEndpoint *) findEndpointForAddress:(NSArray *)addressComponents whileUpdatingArgs:(NSMutableDictionary *)args andSettingFinalLevel:(NSMutableDictionary *)finalLevel
{
	NSMutableDictionary *currentLevel = endpointMap;
	
	// If they left out the /me/ portion of the address for the paths that need it, add it back in
	NSArray *meSpecificAddresses = [[NSArray alloc] initWithObjects:@"program", @"preview", @"transition", @"usk", nil];
	NSArray *me1Addresses = [[NSArray alloc] initWithObjects:@"me", @"1", nil];
	if ([meSpecificAddresses containsObject:[addressComponents objectAtIndex:0]])
		addressComponents = [me1Addresses arrayByAddingObjectsFromArray:addressComponents];
	
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
	
	NSMutableArray *addressComponents = [[NSMutableArray alloc] initWithArray:[[m address] componentsSeparatedByString:@"/"]];
	[addressComponents removeObjectAtIndex:0];
	
	// Remove initial /atem, all addresses will start with that
	if (![[addressComponents objectAtIndex:0] isEqualToString:@"atem"])
	{
		[appDel logMessage:[NSString stringWithFormat:@"All addresses must start with '/atem'. Invalid command: %@", [m address]]];
		return;
	}
	[addressComponents removeObjectAtIndex:0];
	
	// Find the switcher to route the requests to (default to first)
	Switcher *switcher = [[appDel switchers] objectAtIndex:0];
	for (Switcher *s : [appDel switchers])
	{
		if ([[addressComponents objectAtIndex:0] isEqualToString:[s nickname]])
		{
			switcher = s;
			[addressComponents removeObjectAtIndex:0];
		}
	}
	
	if (![switcher isConnected])
		return [appDel logMessage:[NSString stringWithFormat:@"Cannot process command %@ because switcher at address %@ is not connected", [m address], [switcher ipAddress]]];
	
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	[args setValue:[m address] forKey:@"address"];

	NSMutableDictionary *finalLevel = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *finalLevelSecondTry = [[NSMutableDictionary alloc] init];
	OSCValue *value = [m value];

	// First check normal address and values
	OSCEndpoint *endpoint = [self findEndpointForAddress:[NSArray arrayWithArray:addressComponents] whileUpdatingArgs:args andSettingFinalLevel:finalLevel];
	
	// Then try passing the last component of the address as the value and see if that matches any better
	// This would be common with TouchOSC, for example passing /transition/type/mix 1.0 instead of /transition/type mix
	if (endpoint == nil)
	{
		// In TouchOSC specifically, it will send a float value of 1.0 on button press and 0.0 on button release
		// This ignores the button release message to prevent duplicate calls
		if ([[m value] type] == OSCValFloat && [[m value] floatValue] == 0.0)
			return;
		
		if (stringIsNumber([addressComponents lastObject]))
			value = [OSCValue createWithInt:[[addressComponents lastObject] intValue]];
		else
			value = [OSCValue createWithString:[addressComponents lastObject]];
		[addressComponents removeLastObject];
		[args removeAllObjects];
		endpoint = [self findEndpointForAddress:addressComponents whileUpdatingArgs:args andSettingFinalLevel:finalLevelSecondTry];
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
			if ([[endpoint addressTemplate] hasPrefix:validatorKey] && ![validators objectForKey:validatorKey](switcher, args, value))
				return;
		
		// Call handler found for address with paramaterized arguments and value of matching type
		endpoint.handler(switcher, args, value);
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

- (IBMDSwitcherKeyLumaParameters *) getUSKLumaParams:(int)t forSwitcher:(Switcher *)s andME:(int)me
{
	IBMDSwitcherKey* key = [s keyers][me-1][t-1];
	IBMDSwitcherKeyLumaParameters* lumaParams;
	key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
	return lumaParams;
}

- (IBMDSwitcherKeyChromaParameters *) getUSKChromaParams:(int)t forSwitcher:(Switcher *)s andME:(int)me
{
	IBMDSwitcherKey* key = [s keyers][me-1][t-1];
	IBMDSwitcherKeyChromaParameters* chromaParams;
	key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
	return chromaParams;
}

- (IBMDSwitcherKeyDVEParameters *) getUSKDVEParams:(int)t forSwitcher:(Switcher *)s andME:(int)me
{
	IBMDSwitcherKey* key = [s keyers][me-1][t-1];
	IBMDSwitcherKeyDVEParameters* dveParams;
	key->QueryInterface(IID_IBMDSwitcherKeyDVEParameters, (void**)&dveParams);
	return dveParams;
}

- (void) changeTransitionSelection:(int)t select:(bool) select forTransitionParameters:(IBMDSwitcherTransitionParameters *)switcherTransitionParameters
{
	uint32_t currentTransitionSelection;
	switcherTransitionParameters->GetNextTransitionSelection(&currentTransitionSelection);
	
	uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
	uint32_t requestedTransitionSelection = transitionSelections[t];
	
	if (select)
	{
		switcherTransitionParameters->SetNextTransitionSelection(currentTransitionSelection | requestedTransitionSelection);
	}
	else
	{
		// If we are attempting to deselect the only bit set, then default to setting TransitionSelectionBackground
		if ((currentTransitionSelection & ~requestedTransitionSelection) == 0)
			switcherTransitionParameters->SetNextTransitionSelection(bmdSwitcherTransitionSelectionBackground);
		else
			switcherTransitionParameters->SetNextTransitionSelection(currentTransitionSelection & ~requestedTransitionSelection);
	}
}

- (void) setHyperDeckTime:(long long)hyperdeckId time:(NSString *)timeString clip:(BOOL)clipTime forSwitcher:(Switcher *)s
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
	else if (timeComponents.count == 4 && stringIsNumber(timeComponents[0]) && stringIsNumber(timeComponents[1]) && stringIsNumber(timeComponents[2]) && stringIsNumber(timeComponents[3]))
	{
		hour = [timeComponents[0] intValue];
		minute = [timeComponents[1] intValue];
		second = [timeComponents[2] intValue];
		frame = [timeComponents[3] intValue];
	}
	else
		[appDel logMessage:[NSString stringWithFormat:@"Invalid time '%@'. You must specify a time in the format HH:MM:SS (e.g. 00:00:05)", timeString]];
	
	HRESULT status;
	if (clipTime)
		status = [s mHyperdecks][hyperdeckId]->SetCurrentClipTime(hour, minute, second, frame);
	else
		status = [s mHyperdecks][hyperdeckId]->SetCurrentTimelineTime(hour, minute, second, frame);
	
	if (status != S_OK)
		[appDel logMessage:[NSString stringWithFormat:@"Could not seek to time '%@'. Make sure the time is valid and not past the end of the clip/timeline.", timeString]];
}

@end
