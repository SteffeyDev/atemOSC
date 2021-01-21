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
	
	NSMutableAttributedString * helpString = [[NSMutableAttributedString alloc] initWithString:@""];
	
	[self addHeader:@"Polling" toString:helpString];
	[self addEntry:@"Get Status" forAddress:@"/send-status" toString:helpString];

	[self addHeader:@"Transitions" toString:helpString];
	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		[self addEntry:@"T-Bar" forAddress:[NSString stringWithFormat: @"/me/%d/transition/bar", i+1] toString:helpString];
		[self addEntry:@"Cut" forAddress:[NSString stringWithFormat: @"/me/%d/transition/cut", i+1] toString:helpString];
		[self addEntry:@"Auto-Cut" forAddress:[NSString stringWithFormat: @"/me/%d/transition/auto", i+1] toString:helpString];
		[self addEntry:@"Fade-to-black" forAddress:[NSString stringWithFormat: @"/me/%d/transition/ftb", i+1] toString:helpString];
		[self addEntry:@"Preview Transition" forAddress:[NSString stringWithFormat: @"/me/%d/transition/preview", i+1] toString:helpString];
		[self addEntry:@"Set Type" forAddress:[NSString stringWithFormat: @"/me/%d/transition/type <string: mix/dip/wipe/sting/dve>", i+1] toString:helpString];
	}
	
	[self addHeader:@"Sources" toString:helpString];

	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		for (auto const& it : [switcher mInputs])
		{
			NSString* name;
			it.second->GetLongName((CFStringRef*)&name);
			
			if ([name isEqual:@""])
				name = @"Unnamed";
			
			[self addEntry:name forAddress:[NSString stringWithFormat:@"/me/%d/preview %lld",i+1,it.first] toString:helpString];
			[self addEntry:name forAddress:[NSString stringWithFormat:@"/me/%d/program %lld",i+1,it.first] toString:helpString];
			
			[name release];
		}
	}


	[self addHeader:@"Upstream Keyers" toString:helpString];
	for (int i = 0; i<[switcher mMixEffectBlocks].size(); i++)
	{
		[self addEntry:@"Set Tie BKGD" forAddress:[NSString stringWithFormat:@"/me/%d/usk/0/tie", i+1] toString:helpString];
		[self addEntry:@"Toggle Tie BKGD" forAddress:[NSString stringWithFormat:@"/me/%d/usk/0/tie/toggle", i+1] toString:helpString];
		for (int j = 0; j<[switcher keyers][i].size();j++)
		{
			for (OSCEndpoint* endpoint : [appDel endpoints])
			{
				if ([[endpoint addressTemplate] containsString:@"/usk/"])
				{
					NSString *label = [[[endpoint label] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(j+1)] stringValue]] stringByReplacingOccurrencesOfString:@"<me>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];
					NSString *address = [[[endpoint addressTemplate] stringByReplacingOccurrencesOfString:@"<key>" withString:[[NSNumber numberWithInt:(j+1)] stringValue]] stringByReplacingOccurrencesOfString:@"<me>" withString:[[NSNumber numberWithInt:(i+1)] stringValue]];;
					if (endpoint.valueType == OSCValInt)
						address = [address stringByAppendingString:@" <int>"];
					else if (endpoint.valueType == OSCValBool)
						address = [address stringByAppendingString:@" <true|false>"];
					else if (endpoint.valueType == OSCValFloat)
						address = [address stringByAppendingString:@" <decimal>"];
					else if (endpoint.valueType == OSCValString)
						address = [address stringByAppendingString:@" <string>"];
					[self addEntry:label forAddress:address toString:helpString];
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
				if (endpoint.valueType == OSCValInt)
					address = [address stringByAppendingString:@" <int>"];
				else if (endpoint.valueType == OSCValBool)
					address = [address stringByAppendingString:@" <true|false>"];
				else if (endpoint.valueType == OSCValFloat)
					address = [address stringByAppendingString:@" <decimal>"];
				else if (endpoint.valueType == OSCValString)
					address = [address stringByAppendingString:@" <string>"];
				[self addEntry:label forAddress:address toString:helpString];
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
			
			if ([switcher mFairlightAudioSources].at(input.first).size() == 2)
			{
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Gain (left source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/left/gain <float>", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Balance (left sources)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/left/balance <float>", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Gain (right source)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/right/gain <float>", input.first]
				 toString:helpString];
				[self
				 addEntry: [NSString stringWithFormat:@"Audio Input %lld (%@) Balance (right sources)", input.first, inputTypeString]
				 forAddress:[NSString stringWithFormat:@"/audio/input/%lld/right/balance <float>", input.first]
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
	for (int i = 0; i<[switcher mSwitcherInputAuxList].size();i++)
		[self
		 addEntry:[NSString stringWithFormat:@"Set Aux %d to Source",i+1]
		 forAddress:[NSString stringWithFormat:@"/aux/%d\t<valid_program_source>",i+1]
		 toString:helpString];

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
					if (endpoint.valueType == OSCValInt)
						address = [address stringByAppendingString:@" <int>"];
					else if (endpoint.valueType == OSCValBool)
						address = [address stringByAppendingString:@" <true|false>"];
					else if (endpoint.valueType == OSCValFloat)
						address = [address stringByAppendingString:@" <decimal>"];
					else if (endpoint.valueType == OSCValString)
						address = [address stringByAppendingString:@" <string>"];
					[self addEntry:label forAddress:address toString:helpString];
				}
			}
		}
	}

	[self addHeader:@"Macros" toString:helpString];
	for (OSCEndpoint* endpoint : [appDel endpoints])
	{
		if ([[endpoint addressTemplate] containsString:@"/macros/"])
		{
			NSString *address = [endpoint addressTemplate];
			if (endpoint.valueType == OSCValInt)
				address = [address stringByAppendingString:@" <int>"];
			else if (endpoint.valueType == OSCValBool)
				address = [address stringByAppendingString:@" <true|false>"];
			else if (endpoint.valueType == OSCValFloat)
				address = [address stringByAppendingString:@" <decimal>"];
			else if (endpoint.valueType == OSCValString)
				address = [address stringByAppendingString:@" <string>"];
			[self addEntry:[endpoint label] forAddress:address toString:helpString];
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
						address = [address stringByAppendingString:@" <decimal>"];
					else if (endpoint.valueType == OSCValString)
						address = [address stringByAppendingString:@" <string>"];
					[self addEntry:label forAddress:address toString:helpString];
				}
			}
		}
	}
	
	if ([switcher mMixEffectBlocks].size() == 1)
		[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\nNote: Because this switcher only has one Mix Effect Block, you can omit the /me/1 in all commands if you would like.\n"]];
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nNote: Additional addresses are available that provide backward-compatibility with TouchOSC.  See the Readme on Github for details.\n"]];
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nWe add support for addresses on an as-needed basis.  If you are in need of an additional address, open an issue on Github letting us know what it is.\n"]];

	[helpString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,helpString.length)];
	[[helpTextView textStorage] setAttributedString:helpString];
}

@end
