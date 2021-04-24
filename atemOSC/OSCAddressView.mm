//
//  OSCAddressPanel.m
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import "OSCAddressView.h"
#import "BMDSwitcherAPI.h"
#import "AppDelegate.h"
#import "OSCEndpoint.h"

@implementation OSCAddressView

@synthesize helpTextView;

- (void)addHeader:(NSString*)name toString:(NSMutableAttributedString*)helpString
{
	NSDictionary *addressAttribute = @{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:5 size:12]};
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@:\n", name] attributes:addressAttribute]];
}

- (void)addEntry:(NSString*)name forAddress:(NSString*)address toString:(NSMutableAttributedString*)helpString
{
	NSDictionary *infoAttribute = @{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Monaco" traits:NSUnboldFontMask|NSUnitalicFontMask weight:5 size:12]};
	NSDictionary *addressAttribute = @{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:5 size:12]};
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@: ", name] attributes:addressAttribute]];
	if (switcher.nickname && switcher.nickname.length > 0)
		[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/%@%@\n", switcher.nickname, address] attributes:infoAttribute]];
	else
		[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem%@\n", address] attributes:infoAttribute]];
}

- (void)addEntry:(NSString*)name forAddress:(NSString*)address andValueType:(OSCValueType)valueType toString:(NSMutableAttributedString*)helpString
{
	if (valueType == OSCValInt)
		address = [address stringByAppendingString:@" <int>"];
	else if (valueType == OSCValBool)
		address = [address stringByAppendingString:@" <true|false>"];
	else if (valueType == OSCValFloat)
		address = [address stringByAppendingString:@" <float>"];
	else if (valueType == OSCValString)
		address = [address stringByAppendingString:@" <string>"];
	[self addEntry:name forAddress:address toString:helpString];
}

- (void)addEntryForEndpoint:(OSCEndpoint*)endpoint toString:(NSMutableAttributedString*)helpString
{
	[self addEntry:[endpoint label] forAddress:[endpoint addressTemplate] andValueType:[endpoint valueType] toString:helpString];
}

- (void)loadFromSwitcher:(Switcher *)switcher
{
	self->switcher = switcher;
	
	if (![switcher isConnected])
	{
		[[[helpTextView textStorage] mutableString] setString:@""];
		return;
	}
	
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	[helpTextView setAlignment:NSLeftTextAlignment];
	
	NSMutableAttributedString * helpString = [[NSMutableAttributedString alloc] initWithString:@"This nothing more then a exhaustive list of supported OSC addresses for this switcher.  For usage notes and instructions, see the "];
		
	NSMutableAttributedString * docsLink = [[NSMutableAttributedString alloc] initWithString:@"online documentation.\n\n"];
	[docsLink addAttribute: NSLinkAttributeName value: @"http://www.atemosc.com" range: NSMakeRange(0, docsLink.length-3)];
	[helpString appendAttributedString:docsLink];
	
	[self addHeader:@"Polling" toString:helpString];
	[self addEntry:@"Get Status" forAddress:@"/send-status" toString:helpString];

	[self addHeader:@"Transitions" toString:helpString];
	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		NSString *meString = [switcher mMixEffectBlocks].size() == 1 ? @"" : [NSString stringWithFormat:@"/me/%d", i+1];
		[self addEntry:@"T-Bar" forAddress:[NSString stringWithFormat: @"%@/transition/bar", meString] toString:helpString];
		[self addEntry:@"Cut" forAddress:[NSString stringWithFormat: @"%@/transition/cut", meString] toString:helpString];
		[self addEntry:@"Auto-Cut" forAddress:[NSString stringWithFormat: @"%@/transition/auto", meString] toString:helpString];
		[self addEntry:@"Fade-to-black" forAddress:[NSString stringWithFormat: @"%@/transition/ftb", meString] toString:helpString];
		[self addEntry:@"Preview Transition" forAddress:[NSString stringWithFormat: @"%@/transition/preview", meString] toString:helpString];
		[self addEntry:@"Set Type" forAddress:[NSString stringWithFormat: @"%@/transition/type <string: mix/dip/wipe/sting/dve>", meString] toString:helpString];
	}
	
	[self addHeader:@"Sources" toString:helpString];

	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		NSString *meString = [switcher mMixEffectBlocks].size() == 1 ? @"" : [NSString stringWithFormat:@"/me/%d", i+1];
		for (auto const& it : [switcher mInputs])
		{
			CFStringRef nameRef;
			it.second->GetLongName(&nameRef);
			NSString *name = (__bridge NSString*)nameRef;
			
			if ([name isEqual:@""])
				name = @"Unnamed";
			
			[self addEntry:name forAddress:[NSString stringWithFormat:@"%@/preview %lld",meString,it.first] toString:helpString];
			[self addEntry:name forAddress:[NSString stringWithFormat:@"%@/program %lld",meString,it.first] toString:helpString];
		}
	}


	[self addHeader:@"Upstream Keyers" toString:helpString];
	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		NSString *meString = [switcher mMixEffectBlocks].size() == 1 ? @"" : [NSString stringWithFormat:@"/me/%d", i+1];
		[self addEntry:@"Set Tie BKGD" forAddress:[NSString stringWithFormat:@"%@/usk/0/tie", meString] toString:helpString];
		[self addEntry:@"Toggle Tie BKGD" forAddress:[NSString stringWithFormat:@"%@/usk/0/tie/toggle", meString] toString:helpString];
		for (int j = 0; j<[switcher keyers][i].size();j++)
		{
			for (OSCEndpoint* endpoint : [appDel endpoints])
			{
				if ([[endpoint addressTemplate] containsString:@"/usk/"])
				{
					NSString *label = [[[endpoint label] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(j+1)] stringValue]] stringByReplacingOccurrencesOfString:@"<me>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];
					NSString *address = [[[endpoint addressTemplate] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(j+1)] stringValue]] stringByReplacingOccurrencesOfString:@"<me>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];;
					[self addEntry:label forAddress:address andValueType:endpoint.valueType toString:helpString];
				}
			}
		}
	}

	[self addHeader:@"Downstream Keyers" toString:helpString];
	for (int i = 0; i<[switcher dsk].size();i++)
	{
		for (OSCEndpoint* endpoint : [appDel endpoints])
		{
			if ([[endpoint addressTemplate] containsString:@"/dsk/"])
			{
				NSString *label = [[endpoint label] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];
				NSString *address = [[endpoint addressTemplate] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];
				[self addEntry:label forAddress:address andValueType:endpoint.valueType toString:helpString];
			}
		}
	}

	if ([switcher mAudioInputs].size() > 0)
	{
		[self addHeader:@"Audio Inputs" toString:helpString];

		for (auto const& it : [switcher mAudioInputs])
		{
			BMDSwitcherAudioInputType inputType;
			[switcher mAudioInputs].at(it.first)->GetType(&inputType);
			const char *inputTypeString = inputType == bmdSwitcherAudioInputTypeEmbeddedWithVideo ? "camera audio" : (inputType == bmdSwitcherAudioInputTypeMediaPlayer ? "media player" : "external audio-in");

			[self
			 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%s) Gain", it.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/gain <float>", it.first]
			 toString:helpString];
			[self
			 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%s) Balance", it.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/balance <float>", it.first]
			 toString:helpString];
			[self
			 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%s) Mix Option", it.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/mix <string> = 'afv' | 'on' | 'off'", it.first]
			 toString:helpString];
		}
	}

	if ([switcher mAudioMixer] != nil)
	{
		[self addHeader:@"Audio Output (Mix)" toString:helpString];
		[self addEntry:@"Audio Output Gain" forAddress:@"/audio/output/gain <float>" toString:helpString];
		[self addEntry:@"Audio Output Balance" forAddress:@"/audio/output/balance <float>" toString:helpString];
	}
	
	if ([switcher mFairlightAudioInputs].size() > 0)
	{
		[self addHeader:@"Audio Inputs" toString:helpString];
		
		for (auto const& input : [switcher mFairlightAudioInputs])
		{
			BMDSwitcherFairlightAudioInputType inputType;
			[switcher mFairlightAudioInputs].at(input.first)->GetType(&inputType);
			NSString *inputTypeString = @"unknown";
			if (inputType == bmdSwitcherFairlightAudioInputTypeMADI)
				inputTypeString = @"MADI";
			else if (inputType == bmdSwitcherFairlightAudioInputTypeAudioIn)
				inputTypeString = @"external audio-in";
			else if (inputType == bmdSwitcherFairlightAudioInputTypeMediaPlayer)
				inputTypeString = @"media player";
			else if (inputType == bmdSwitcherFairlightAudioInputTypeEmbeddedWithVideo)
				inputTypeString = @"camera audio";
			
			[self
			 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Gain (all sources)", input.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/gain <float>", input.first]
			 toString:helpString];
			[self
			 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Balance (all sources)", input.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/balance <float>", input.first]
			 toString:helpString];
			[self
			 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%@) Mix Option (all sources)", input.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/mix <string> = 'afv' | 'on' | 'off'", input.first]
			 toString:helpString];
			
			if ([switcher mFairlightAudioSources].at(input.first).size() == 2)
			{
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Gain (left source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/left/gain <float>", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Balance (left source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/left/balance <float>", input.first]
				 toString:helpString];
				[self
				 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%@) Mix Option (left source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/left/mix <string> = 'afv' | 'on' | 'off'", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Gain (right source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/right/gain <float>", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Balance (right source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/right/balance <float>", input.first]
				 toString:helpString];
				[self
				 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%@) Mix Option (right source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/right/mix <string> = 'afv' | 'on' | 'off'", input.first]
				 toString:helpString];
			}
		}
	}

	if ([switcher mFairlightAudioMixer] != nil)
	{
		[self addHeader:@"Audio Output (Mix)" toString:helpString];
		[self addEntry:@"Audio Output Gain" forAddress:@"/audio/output/gain <float>" toString:helpString];
	}

	[self addHeader:@"Aux Outputs" toString:helpString];
	for (auto const& it : [switcher mAuxInputs])
	{
		[self
		 addEntry:[NSString stringWithFormat:@"Set Aux %lld to Source",it.first]
		 forAddress:[NSString stringWithFormat:@"/aux/%lld\t<valid_program_source>",it.first]
		 toString:helpString];
	}		

	if ([switcher mMediaPlayers].size() > 0)
	{
		uint32_t clipCount;
		uint32_t stillCount;
		HRESULT result;
		result = [switcher mMediaPool]->GetClipCount(&clipCount);
		if (FAILED(result))
		{
			// the default number of clips
			clipCount = 2;
		}

		IBMDSwitcherStills* mStills;
		result = [switcher mMediaPool]->GetStills(&mStills);
		if (FAILED(result))
		{
			// ATEM TVS only supports 20 stills, the others are 32
			stillCount = 20;
		}
		else
		{
			result = mStills->GetCount(&stillCount);
			if (FAILED(result))
			{
				// ATEM TVS only supports 20 stills, the others are 32
				stillCount = 20;
			}
		}

		[self addHeader:@"Media Players" toString:helpString];
		for (int i = 0; i < [switcher mMediaPlayers].size(); i++)
		{
			for (int j = 0; j < clipCount; j++)
				[self
				 addEntry:[NSString stringWithFormat:@"Set MP %d to Clip %d",i+1,j+1]
				 forAddress:[NSString stringWithFormat:@"/mplayer/%d/clip/%d",i+1,j+1]
				 toString:helpString];

			for (int j = 0; j < stillCount; j++)
				[self
				 addEntry:[NSString stringWithFormat:@"Set MP %d to Still %d",i+1,j+1]
				 forAddress:[NSString stringWithFormat:@"/mplayer/%d/still/%d",i+1,j+1]
				 toString:helpString];
		}
	}

	if ([switcher mSuperSourceBoxes].size() > 0)
	{
		[self addHeader:@"Super Source" toString:helpString];

		for (int i = 1; i <= [switcher mSuperSourceBoxes].size(); i++)
		{
			for (OSCEndpoint* endpoint : [appDel endpoints])
			{
				if ([[endpoint addressTemplate] containsString:@"/supersource/"])
				{
					NSString *label = [[endpoint label] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:i] stringValue]];
					NSString *address = [[endpoint addressTemplate] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:i] stringValue]];
					[self addEntry:label forAddress:address andValueType:endpoint.valueType toString:helpString];
				}
			}
		}
	}

	[self addHeader:@"Macros" toString:helpString];
	for (OSCEndpoint* endpoint : [appDel endpoints])
	{
		if ([[endpoint addressTemplate] containsString:@"/macros/"])
		{
			[self addEntryForEndpoint:endpoint toString:helpString];
		}
	}
	
	for (auto const& it : [switcher mHyperdecks])
	{
		BMDSwitcherHyperDeckConnectionStatus status;
		it.second->GetConnectionStatus(&status);
		if (status == bmdSwitcherHyperDeckConnectionStatusConnected)
		{
			if (it.first == 0)
				[self addHeader:@"HyperDecks" toString:helpString];

			for (OSCEndpoint* endpoint : [appDel endpoints])
			{
				if ([[endpoint addressTemplate] containsString:@"/hyperdeck/"])
				{
					NSString *label = [[endpoint label] stringByReplacingOccurrencesOfString:@"<number>" withString:[[NSNumber numberWithLongLong:it.first+1] stringValue]];
					NSString *address = [[endpoint addressTemplate] stringByReplacingOccurrencesOfString:@"<number>" withString:[[NSNumber numberWithLongLong:it.first+1] stringValue]];
					if (endpoint.valueType == OSCValInt)
						address = [address stringByAppendingString:@" <int>"];
					else if (endpoint.valueType == OSCValBool)
						address = [address stringByAppendingString:@" <true|false>"];
					else if (endpoint.valueType == OSCValFloat)
						address = [address stringByAppendingString:@" <float>"];
					else if (endpoint.valueType == OSCValString)
						address = [address stringByAppendingString:@" <string>"];
					[self addEntry:label forAddress:address toString:helpString];
				}
			}
		}
	}
	
	if ([switcher mRecordAV])
	{
		[self addHeader:@"Recording" toString:helpString];
		for (OSCEndpoint* endpoint : [appDel endpoints])
		{
			if ([[endpoint addressTemplate] containsString:@"/recording/"])
			{
				[self addEntryForEndpoint:endpoint toString:helpString];
			}
		}
	}
	
	if ([switcher mStreamRTMP])
	{
		[self addHeader:@"Streaming" toString:helpString];
		for (OSCEndpoint* endpoint : [appDel endpoints])
		{
			if ([[endpoint addressTemplate] containsString:@"/stream/"])
			{
				[self addEntryForEndpoint:endpoint toString:helpString];
			}
		}
	}
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nNote: Additional addresses are available that provide backward-compatibility with TouchOSC.  See the Readme on Github for details.\n"]];
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nWe add support for addresses on an as-needed basis.  If you are in need of an additional address, open an issue on Github letting us know what it is.\n"]];

	if ([helpTextView textColor])
		[helpString addAttribute:NSForegroundColorAttributeName value:[helpTextView textColor] range:NSMakeRange(0,helpString.length)];
	[[helpTextView textStorage] setAttributedString:helpString];
}

@end
