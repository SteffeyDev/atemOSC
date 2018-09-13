//
//  OSCAddressPanel.m
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import "OSCAddressPanel.h"
#import "BMDSwitcherAPI.h"
#import "AppDelegate.h"

@implementation OSCAddressPanel

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

- (void)setupWithDelegate:(AppDelegate *)appDel
{
	//set helptext
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

	[self addHeader:@"Upstream Keyers" toString:helpString];
	[self addEntry:@"Set Tie BKGD" forAddress:@"/atem/usk/0/tie" toString:helpString];
	[self addEntry:@"Toggle Tie BKGD" forAddress:@"/atem/usk/0/tie/toggle" toString:helpString];
	for (int i = 0; i<[appDel keyers].size();i++)
	{
		[self addEntry:[NSString stringWithFormat:@"Set USK%d On Air",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/on-air\t<0|1>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Toggle On Air USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/on-air/toggle",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Tie USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/tie\t<0|1>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Toggle Tie USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/tie/toggle",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Next-Transition State USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/tie/set-next\t<0|1>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Fill Source USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/source/fill\t<int>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Cut Source USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/source/cut\t<int>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Clip Luma Parameter USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/clip\t<float>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Gain Luma Parameter USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/gain\t<float>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Pre-Multiplied Luma Parameter USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/pre-multiplied\t<bool>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Inverse Luma Parameter USK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/inverse\t<bool>",i+1] toString:helpString];
	}

	[self addHeader:@"Downstream Keyers" toString:helpString];
	for (int i = 0; i<[appDel dsk].size();i++)
	{
		[self addEntry:[NSString stringWithFormat:@"Set DSK%d On Air",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/on-air\t<0|1>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Auto-Transistion DSK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/on-air/auto",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Toggle On Air DSK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/on-air/toggle",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Tie DSK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/tie\t<0|1>",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Toggle Tie DSK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/tie/toggle",i+1] toString:helpString];
		[self addEntry:[NSString stringWithFormat:@"Set Next-Transition State DSK%d",i+1] forAddress:[NSString stringWithFormat:@"/atem/dsk/%d/tie/set-next\t<0|1>",i+1] toString:helpString];
	}

	[self addHeader:@"Sources" toString:helpString];

	HRESULT result;
	IBMDSwitcherInputIterator* inputIterator = NULL;
	IBMDSwitcherInput* input = NULL;

	result = [appDel mSwitcher]->CreateIterator(IID_IBMDSwitcherInputIterator, (void**)&inputIterator);
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

	[self addHeader:@"Audio Inputs" toString:helpString];

	for (auto const& it : [appDel mAudioInputs])
	{
		BMDSwitcherAudioInputType inputType;
		[appDel mAudioInputs].at(it.first)->GetType(&inputType);
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

	[self addHeader:@"Audio Output (Mix)" toString:helpString];
	[self addEntry:@"Audio Output Gain" forAddress:@"/atem/audio/output/gain <float>" toString:helpString];
	[self addEntry:@"Audio Output Balance" forAddress:@"/atem/audio/output/balance <float>" toString:helpString];

	[self addHeader:@"Aux Outputs" toString:helpString];
	for (int i = 0; i<[appDel mSwitcherInputAuxList].size();i++)
		[self
		 addEntry:[NSString stringWithFormat:@"Set Aux %d to Source",i+1]
		 forAddress:[NSString stringWithFormat:@"/atem/aux/%d\t<valid_program_source>",i+1]
		 toString:helpString];

	if ([appDel mMediaPlayers].size() > 0)
	{
		uint32_t clipCount;
		uint32_t stillCount;
		HRESULT result;
		result = [appDel mMediaPool]->GetClipCount(&clipCount);
		if (FAILED(result))
		{
			// the default number of clips
			clipCount = 2;
		}

		IBMDSwitcherStills* mStills;
		result = [appDel mMediaPool]->GetStills(&mStills);
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
		for (int i = 0; i < [appDel mMediaPlayers].size(); i++)
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

	if ([appDel mSuperSourceBoxes].size() > 0)
	{
		[self addHeader:@"Super Source" toString:helpString];
		[self addEntry:@"Set the border enabled flag" forAddress:@"/atem/supersource/border-enabled\t<0|1>" toString:helpString];
		[self addEntry:@"Set the border outer width" forAddress:@"/atem/supersource/border-outer\t<float>" toString:helpString];
		[self addEntry:@"Set the border inner width" forAddress:@"/atem/supersource/border-inner\t<float>" toString:helpString];
		[self addEntry:@"Set the border hue" forAddress:@"/atem/supersource/border-hue\t<float>" toString:helpString];
		[self addEntry:@"Set the border saturation" forAddress:@"/atem/supersource/border-saturation\t<float>" toString:helpString];
		[self addEntry:@"Set the border luminescence" forAddress:@"/atem/supersource/border-luminescence\t<float>" toString:helpString];

		for (int i = 1; i <= [appDel mSuperSourceBoxes].size(); i++)
		{
			[self addEntry:[NSString stringWithFormat:@"Set Box %d enabled",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/enabled\t<0|1>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Input source",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/source\t<see sources for valid options>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Position X",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/x\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Position Y",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/y\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Size",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/size\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Cropped Enabled",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/cropped\t<0|1>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Crop Top",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-top\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Crop Bottom",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-bottom\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Crop Left",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-left\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Set Box %d Crop Right",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-right\t<float>",i] toString:helpString];
			[self addEntry:[NSString stringWithFormat:@"Reset Box %d Crop",i] forAddress:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-reset\t<1>",i] toString:helpString];
		}
	}

	[self addHeader:@"Macros" toString:helpString];
	[self addEntry:@"Get the Maximum Number of Macros" forAddress:@"/atem/macros/max-number" toString:helpString];
	[self addEntry:@"Stop the currently active Macro (if any)" forAddress:@"/atem/macros/stop" toString:helpString];
	[self addEntry:@"Get the Name of a Macro" forAddress:@"/atem/macros/<index>/name" toString:helpString];
	[self addEntry:@"Get the Description of a Macro" forAddress:@"/atem/macros/<index>/description" toString:helpString];
	[self addEntry:@"Get whether the Macro at <index> is valid" forAddress:@"/atem/macros/<index>/is-valid" toString:helpString];
	[self addEntry:@"Run the Macro at <index>" forAddress:@"/atem/macros/<index>/run" toString:helpString];

	[helpString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,helpString.length)];
	[[helpTextView textStorage] setAttributedString:helpString];
}

@end
