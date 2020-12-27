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
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", address] attributes:infoAttribute]];
}

- (void)loadFromSwitcher:(Switcher *)switcher
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	[helpTextView setAlignment:NSLeftTextAlignment];
	
	NSMutableAttributedString * helpString = [[NSMutableAttributedString alloc] initWithString:@""];
	
	[self addHeader:@"Polling" toString:helpString];
	[self addEntry:@"Get Status" forAddress:@"/atem/send-status" toString:helpString];

	[self addHeader:@"Transitions" toString:helpString];
	[self addEntry:@"T-Bar" forAddress:@"/atem/transition/bar" toString:helpString];
	[self addEntry:@"Cut" forAddress:@"/atem/transition/cut" toString:helpString];
	[self addEntry:@"Auto-Cut" forAddress:@"/atem/transition/auto" toString:helpString];
	[self addEntry:@"Fade-to-black" forAddress:@"/atem/transition/ftb" toString:helpString];
	[self addEntry:@"Preview Transition" forAddress:@"/atem/transition/preview" toString:helpString];

	[self addHeader:@"Transition type" toString:helpString];
	[self addEntry:@"Set to Mix" forAddress:@"/atem/transition/set-type/mix" toString:helpString];
	[self addEntry:@"Set to Dip" forAddress:@"/atem/transition/set-type/dip" toString:helpString];
	[self addEntry:@"Set to Wipe" forAddress:@"/atem/transition/set-type/wipe" toString:helpString];
	[self addEntry:@"Set to Stinger" forAddress:@"/atem/transition/set-type/sting" toString:helpString];
	[self addEntry:@"Set to DVE" forAddress:@"/atem/transition/set-type/dve" toString:helpString];
	
	[self addHeader:@"Sources" toString:helpString];

	HRESULT result;
	IBMDSwitcherInputIterator* inputIterator = NULL;
	IBMDSwitcherInput* input = NULL;

	result = [switcher mSwitcher]->CreateIterator(IID_IBMDSwitcherInputIterator, (void**)&inputIterator);
	if (FAILED(result))
	{
		NSLog(@"Could not create IBMDSwitcherInputIterator iterator");
		return;
	}

	while (S_OK == inputIterator->Next(&input))
	{
		NSString* name;
		BMDSwitcherInputId id;
		
		input->GetInputId(&id);
		input->GetLongName((CFStringRef*)&name);
		
		if ([name isEqual:@""])
			name = @"Unnamed";
		
		[self addEntry:name forAddress:[NSString stringWithFormat:@"/atem/program/%ld",(long)id] toString:helpString];
		
		input->Release();
		[name release];
	}
	inputIterator->Release();

	[self addHeader:@"Upstream Keyers" toString:helpString];
	[self addEntry:@"Set Tie BKGD" forAddress:@"/atem/usk/0/tie" toString:helpString];
	[self addEntry:@"Toggle Tie BKGD" forAddress:@"/atem/usk/0/tie/toggle" toString:helpString];
	for (int i = 0; i<[switcher keyers].size();i++)
	{
		for (OSCEndpoint* endpoint : [switcher endpoints])
		{
			if ([[endpoint addressTemplate] containsString:@"/usk/"])
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
			 forAddress:[NSString stringWithFormat:@"/atem/audio/input/%lld/gain <float>", it.first]
			 toString:helpString];
			[self
			 addEntry:[NSString stringWithFormat:@"Audio Input %lld (%s) Balance", it.first, inputTypeString]
			 forAddress:[NSString stringWithFormat:@"/atem/audio/input/%lld/balance <float>", it.first]
			 toString:helpString];
		}
	}

	if ([switcher mAudioMixer] != nil)
	{
		[self addHeader:@"Audio Output (Mix)" toString:helpString];
		[self addEntry:@"Audio Output Gain" forAddress:@"/atem/audio/output/gain <float>" toString:helpString];
		[self addEntry:@"Audio Output Balance" forAddress:@"/atem/audio/output/balance <float>" toString:helpString];
	}
	
	if ([switcher mFairlightAudioSources].size() > 0)
	{
		[self addHeader:@"Fairlight Audio Sources" toString:helpString];
		
		for (auto const& it : [switcher mFairlightAudioSources])
		{
			[self
			 addEntry:[NSString stringWithFormat:@"Fairlight Audio Source %lld Gain", it.first]
			 forAddress:[NSString stringWithFormat:@"/atem/fairlight-audio/source/%lld/gain <float>", it.first]
			 toString:helpString];
			[self
			 addEntry:[NSString stringWithFormat:@"Fairlight Audio Source %lld Pan", it.first]
			 forAddress:[NSString stringWithFormat:@"/atem/fairlight-audio/source/%lld/pan <float>", it.first]
			 toString:helpString];
		}
	}

	if ([switcher mFairlightAudioMixer] != nil)
	{
		[self addHeader:@"Fairlight Audio Output (Mix)" toString:helpString];
		[self addEntry:@"Fairlight Audio Output Gain" forAddress:@"/atem/fairlight-audio/output/gain <float>" toString:helpString];
	}

	[self addHeader:@"Aux Outputs" toString:helpString];
	for (int i = 0; i<[switcher mSwitcherInputAuxList].size();i++)
		[self
		 addEntry:[NSString stringWithFormat:@"Set Aux %d to Source",i+1]
		 forAddress:[NSString stringWithFormat:@"/atem/aux/%d\t<valid_program_source>",i+1]
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
				 forAddress:[NSString stringWithFormat:@"/atem/mplayer/%d/clip/%d",i+1,j+1]
				 toString:helpString];

			for (int j = 0; j < stillCount; j++)
				[self
				 addEntry:[NSString stringWithFormat:@"Set MP %d to Still %d",i+1,j+1]
				 forAddress:[NSString stringWithFormat:@"/atem/mplayer/%d/still/%d",i+1,j+1]
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
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\nNote: Additional addresses are available that provide backward-compatibility with TouchOSC.  See the Readme on Github for details.\n\n"]];
	
	[helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"We add support for addresses on an as-needed basis.  If you are in need of an additional address, open an issue on Github letting us know what it is.\n"]];

	[helpString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,helpString.length)];
	[[helpTextView textStorage] setAttributedString:helpString];
}

@end
