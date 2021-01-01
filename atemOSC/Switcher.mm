//
//  Switcher.m
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import "Switcher.h"
#import "AppDelegate.h"
#import "Window.h"

@implementation Switcher

@synthesize ipAddress;
@synthesize nickname;
@synthesize feedbackIpAddress;
@synthesize feedbackPort;
@synthesize connectAutomatically;

@synthesize uid;

@synthesize isConnected;
@synthesize connectionStatus;

@synthesize outPort;

@synthesize productName;

@synthesize mMixEffectBlock;
@synthesize mMixEffectBlockMonitor;
@synthesize keyers;
@synthesize dsk;
@synthesize switcherTransitionParameters;
@synthesize mMediaPool;
@synthesize mMediaPlayers;
@synthesize mMacroPool;
@synthesize mSuperSource;
@synthesize mMacroControl;
@synthesize mSuperSourceBoxes;
@synthesize mInputs;
@synthesize mSwitcherInputAuxList;

@synthesize mAudioInputs;
@synthesize mAudioMixer;

@synthesize mFairlightAudioSources;
@synthesize mFairlightAudioMixer;

@synthesize mSwitcher;
@synthesize mHyperdecks;

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.uid forKey:@"uid"];
	[encoder encodeObject:self.ipAddress forKey:@"ipAddress"];
	[encoder encodeObject:self.feedbackIpAddress forKey:@"feedbackIpAddress"];
	[encoder encodeObject:[[NSNumber numberWithInt: self.feedbackPort] stringValue] forKey:@"feedbackPort"];
	[encoder encodeObject:self.nickname forKey:@"nickname"];
	[encoder encodeObject:[[NSNumber numberWithBool: self.connectAutomatically] stringValue] forKey:@"connectAutomatically"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if((self = [self init])) {
		//decode properties, other class vars
		self.uid = [decoder decodeObjectForKey:@"uid"];
		self.ipAddress = [decoder decodeObjectForKey:@"ipAddress"];
		self.feedbackIpAddress = [decoder decodeObjectForKey:@"feedbackIpAddress"];
		self.feedbackPort = [[decoder decodeObjectForKey:@"feedbackPort"] intValue];
		self.nickname = [decoder decodeObjectForKey:@"nickname"];
		self.connectAutomatically = [[decoder decodeObjectForKey:@"connectAutomatically"] boolValue];
	}
	return self;
}

- (id)init
{
	self = [super init];
	
	mSwitcher = NULL;
	mMixEffectBlock = NULL;
	mMediaPool = NULL;
	mMacroPool = NULL;
	mSuperSource = NULL;
	mMacroControl = NULL;
	mAudioMixer = NULL;
	
	isConnected = FALSE;
	connectionStatus = @"Not Connected";
	
	connectAutomatically = YES;
	
	return self;
}

- (void)updateFeedback
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	if (feedbackIpAddress != nil && feedbackPort > 0)
	{
		if (outPort == nil)
			outPort = [appDel.manager createNewOutputToAddress:feedbackIpAddress atPort:feedbackPort withLabel:@"atemOSC"];
		else
		{
			if (![feedbackIpAddress isEqualToString: [outPort addressString]])
				[outPort setAddressString:feedbackIpAddress];
			if (feedbackPort != [outPort port])
				[outPort setPort:feedbackPort];
		}
	}
}

- (void)connectBMD
{
	[self connectBMD: 5 toIpAddress:[ipAddress copy]];
}
- (void)connectBMD:(int)attemptsRemaining toIpAddress:(NSString *)ipAddress
{
	// Handle case when we run out of attempts or the IP address changes while trying to connect
	if (attemptsRemaining <= 0 || ![ipAddress isEqualToString:[self ipAddress]])
	{
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		// AppDelegate can only be retrieved from main thread
		AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
		Window* window = (Window *) [[NSApplication sharedApplication] mainWindow];

		if (![[self connectionStatus] isEqualToString:@"Connecting"])
		{
			[self setConnectionStatus: @"Connecting"];
			[[window outlineView] reloadItem:self];
		}
		
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
		dispatch_async(queue, ^{
			BMDSwitcherConnectToFailure            failReason;
			
			// Note that ConnectTo() can take several seconds to return, both for success or failure,
			// depending upon hostname resolution and network response times, so it may be best to
			// do this in a separate thread to prevent the main GUI thread blocking.
			HRESULT hr = [appDel mSwitcherDiscovery]->ConnectTo((CFStringRef)ipAddress, &mSwitcher, &failReason);
			if (SUCCEEDED(hr))
			{
				[self switcherConnected];
			}
			else
			{
				NSString* reason;
				BOOL retry = YES;
				switch (failReason)
				{
					case bmdSwitcherConnectToFailureNoResponse:
						reason = @"No response from Switcher";
						break;
					case bmdSwitcherConnectToFailureIncompatibleFirmware:
						reason = @"Switcher has incompatible firmware";
						retry = NO;
						break;
					case bmdSwitcherConnectToFailureCorruptData:
						reason = @"Corrupt data was received during connection attempt";
						break;
					case bmdSwitcherConnectToFailureStateSync:
						reason = @"State synchronisation failed during connection attempt";
						break;
					case bmdSwitcherConnectToFailureStateSyncTimedOut:
						reason = @"State synchronisation timed out during connection attempt";
						break;
					default:
						reason = @"Connection failed for unknown reason";
				}
				if (attemptsRemaining > 1)
				{
					//Delay 2 seconds before everytime connect/reconnect
					//Because the session ID from ATEM switcher will alive not more then 2 seconds
					//After 2 second of idle, the session will be reset then reconnect won't cause error
					double delayInSeconds = 2.0;
					dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
					dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
								   ^(void){
									   //To run in background thread
									   [self connectBMD: attemptsRemaining-1 toIpAddress:ipAddress];
								   });
					if (retry)
						[appDel logMessage:[NSString stringWithFormat:@"%@: %@, retrying %d more times", ipAddress, reason, attemptsRemaining-1]];
					else
						[appDel logMessage:[NSString stringWithFormat:@":%@: %@", ipAddress, reason]];
				}
				else
				{
					[appDel logMessage:[NSString stringWithFormat:@"%@: Failed to connect after 5 attempts", ipAddress]];
					dispatch_async(dispatch_get_main_queue(), ^{
						[self setConnectionStatus:@"Failed to Connect"];
						[[window outlineView] reloadItem:self];
						if ([[window connectionView] switcher] == self)
							[[window connectionView] reload];
					});
				}
			}
		});
	});
		
	
}

- (void)switcherConnected
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	HRESULT result;

	[self setIsConnected: YES];
	[self setConnectionStatus:@"Connected"];
	
	if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
	{
		appDel.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"receiving OSC messages"];
	}
	
	[self setupMonitors];
	
	[self updateFeedback];
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/led/green"];
	[newMsg addFloat:1.0];
	[outPort sendThisMessage:newMsg];
	newMsg = [OSCMessage createWithAddress:@"/atem/led/red"];
	[newMsg addFloat:0.0];
	[outPort sendThisMessage:newMsg];
	
	NSString* productName = @"N/A";
	if (FAILED(mSwitcher->GetProductName((CFStringRef*)&productName)))
	{
		[appDel logMessage:@"Could not get switcher product name"];
	}
	
	[self setProductName:productName];
	dispatch_async(dispatch_get_main_queue(), ^{
		Window* window = (Window *) [[NSApplication sharedApplication] mainWindow];
		[[window outlineView] reloadItem:self];
		if ([[window connectionView] switcher] == self)
		{
			[[[window connectionView] productNameTextField] setStringValue:productName];
		}
	});
	
	mSwitcher->AddCallback(mSwitcherMonitor);
	
	// Get the mix effect block iterator
	IBMDSwitcherMixEffectBlockIterator* iterator = NULL;
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherMixEffectBlockIterator, (void**)&iterator)))
	{
		// Use the first Mix Effect Block
		if (S_OK == iterator->Next(&mMixEffectBlock))
		{
			mMixEffectBlock->AddCallback(mMixEffectBlockMonitor);
			mMixEffectBlockMonitor->updateSliderPosition();
			
			if (SUCCEEDED(mMixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&switcherTransitionParameters)))
			{
				switcherTransitionParameters->AddCallback(mTransitionParametersMonitor);
			}
			else
			{
				[appDel logMessage:@"[Debug] Could not get IBMDSwitcherTransitionParameters"];
			}
			
		}
		else
		{
			[appDel logMessage:@"[Debug] Could not get the first IBMDSwitcherMixEffectBlock"];
		}
		
		iterator->Release();
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not create IBMDSwitcherMixEffectBlockIterator iterator"];
	}
	
	
	// Create an InputMonitor for each input so we can catch any changes to input names
	IBMDSwitcherInputIterator* inputIterator = NULL;
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherInputIterator, (void**)&inputIterator)))
	{
		IBMDSwitcherInput* input = NULL;
		
		// For every input, install a callback to monitor property changes on the input
		while (S_OK == inputIterator->Next(&input))
		{
			BMDSwitcherInputId inputId;
			input->GetInputId(&inputId);
			mInputs.insert(std::make_pair(inputId, input));
			InputMonitor *monitor = new InputMonitor(self, inputId);
			input->AddCallback(monitor);
			mMonitors.push_back(monitor);
			mInputMonitors.insert(std::make_pair(inputId, monitor));
			
			IBMDSwitcherInputAux* auxObj;
			result = input->QueryInterface(IID_IBMDSwitcherInputAux, (void**)&auxObj);
			if (SUCCEEDED(result))
			{
				BMDSwitcherInputId auxId;
				result = auxObj->GetInputSource(&auxId);
				if (SUCCEEDED(result))
				{
					mSwitcherInputAuxList.push_back(auxObj);
				}
			}
		}
		inputIterator->Release();
		inputIterator = NULL;
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not create IBMDSwitcherInputIterator iterator"];
	}
	
	
	//Upstream Keyer
	IBMDSwitcherKeyIterator* keyIterator = NULL;
	IBMDSwitcherKey* key = NULL;
	if (SUCCEEDED(mMixEffectBlock->CreateIterator(IID_IBMDSwitcherKeyIterator, (void**)&keyIterator)))
	{
		while (S_OK == keyIterator->Next(&key))
		{
			keyers.push_back(key);
			key->AddCallback(mUpstreamKeyerMonitor);
			
			IBMDSwitcherKeyLumaParameters* lumaParams;
			if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
				lumaParams->AddCallback(mUpstreamKeyerLumaParametersMonitor);
			
			IBMDSwitcherKeyChromaParameters* chromaParams;
			if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
				chromaParams->AddCallback(mUpstreamKeyerChromaParametersMonitor);
		}
		keyIterator->Release();
		keyIterator = NULL;
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not create IBMDSwitcherKeyIterator iterator"];
	}
	
	
	//Downstream Keyer
	IBMDSwitcherDownstreamKeyIterator* dskIterator = NULL;
	IBMDSwitcherDownstreamKey* downstreamKey = NULL;
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherDownstreamKeyIterator, (void**)&dskIterator)))
	{
		while (S_OK == dskIterator->Next(&downstreamKey))
		{
			dsk.push_back(downstreamKey);
			downstreamKey->AddCallback(mDownstreamKeyerMonitor);
		}
		dskIterator->Release();
		dskIterator = NULL;
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not create IBMDSwitcherDownstreamKeyIterator iterator"];
	}
	
	// Media Players
	IBMDSwitcherMediaPlayerIterator* mediaPlayerIterator = NULL;
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherMediaPlayerIterator, (void**)&mediaPlayerIterator)))
	{
		IBMDSwitcherMediaPlayer* mediaPlayer = NULL;
		while (S_OK == mediaPlayerIterator->Next(&mediaPlayer))
		{
			mMediaPlayers.push_back(mediaPlayer);
		}
		mediaPlayerIterator->Release();
		mediaPlayerIterator = NULL;
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not create IBMDSwitcherMediaPlayerIterator iterator"];
	}
	
	// get media pool
	if (FAILED(mSwitcher->QueryInterface(IID_IBMDSwitcherMediaPool, (void**)&mMediaPool)))
	{
		[appDel logMessage:@"[Debug] Could not get IBMDSwitcherMediaPool interface"];
	}
	
	// get macro pool
	if (SUCCEEDED(mSwitcher->QueryInterface(IID_IBMDSwitcherMacroPool, (void**)&mMacroPool)))
	{
		mMacroPool->AddCallback(mMacroPoolMonitor);
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not get IID_IBMDSwitcherMacroPool interface"];
	}
	
	// get macro controller
	if (FAILED(mSwitcher->QueryInterface(IID_IBMDSwitcherMacroControl, (void**)&mMacroControl)))
	{
		[appDel logMessage:@"[Debug] Could not get IID_IBMDSwitcherMacroControl interface"];
	}
	
	// Super source
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherInputSuperSource, (void**)&mSuperSource))) {
		IBMDSwitcherSuperSourceBoxIterator* superSourceIterator = NULL;
		if (SUCCEEDED(mSuperSource->CreateIterator(IID_IBMDSwitcherSuperSourceBoxIterator, (void**)&superSourceIterator)))
		{
			IBMDSwitcherSuperSourceBox* superSourceBox = NULL;
			while (S_OK == superSourceIterator->Next(&superSourceBox))
			{
				mSuperSourceBoxes.push_back(superSourceBox);
			}
			superSourceIterator->Release();
			superSourceIterator = NULL;
		}
		else
		{
			[appDel logMessage:@"[Debug] Could not create IBMDSwitcherSuperSourceBoxIterator iterator"];
		}
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not get IBMDSwitcherInputSuperSource interface"];
	}
	
	// Audio Mixer (Output)
	if (SUCCEEDED(mSwitcher->QueryInterface(IID_IBMDSwitcherAudioMixer, (void**)&mAudioMixer)))
	{
		mAudioMixer->AddCallback(mAudioMixerMonitor);
		
		// Audio Inputs
		IBMDSwitcherAudioInputIterator* audioInputIterator = NULL;
		if (SUCCEEDED(mAudioMixer->CreateIterator(IID_IBMDSwitcherAudioInputIterator, (void**)&audioInputIterator)))
		{
			IBMDSwitcherAudioInput* audioInput = NULL;
			while (S_OK == audioInputIterator->Next(&audioInput))
			{
				BMDSwitcherAudioInputId inputId;
				audioInput->GetAudioInputId(&inputId);
				mAudioInputs.insert(std::make_pair(inputId, audioInput));
				AudioInputMonitor *monitor = new AudioInputMonitor(self, inputId);
				audioInput->AddCallback(monitor);
				mMonitors.push_back(monitor);
				mAudioInputMonitors.insert(std::make_pair(inputId, monitor));
			}
			audioInputIterator->Release();
			audioInputIterator = NULL;
		}
		else
		{
			[appDel logMessage:[NSString stringWithFormat:@"[Debug] Could not create IBMDSwitcherAudioInputIterator iterator. code: %d", HRESULT_CODE(result)]];
		}
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not get IBMDSwitcherAudioMixer interface (If your switcher supports Fairlight audio, you can ignore this)"];
	}
	
	// Fairlight Audio Mixer
	if (SUCCEEDED(mSwitcher->QueryInterface(IID_IBMDSwitcherFairlightAudioMixer, (void**)&mFairlightAudioMixer))) {
		mFairlightAudioMixer->AddCallback(mFairlightAudioMixerMonitor);
		
		// Audio Inputs
		IBMDSwitcherFairlightAudioInputIterator* audioInputIterator = NULL;
		if (SUCCEEDED(mFairlightAudioMixer->CreateIterator(IID_IBMDSwitcherFairlightAudioInputIterator, (void**)&audioInputIterator)))
		{
			IBMDSwitcherFairlightAudioInput* audioInput = NULL;
			while (S_OK == audioInputIterator->Next(&audioInput))
			{
				// Audio Sources
				IBMDSwitcherFairlightAudioSourceIterator* audioSourceIterator = NULL;
				if (SUCCEEDED(audioInput->CreateIterator(IID_IBMDSwitcherFairlightAudioSourceIterator, (void**)&audioSourceIterator)))
				{
					IBMDSwitcherFairlightAudioSource* audioSource = NULL;
					while (S_OK == audioSourceIterator->Next(&audioSource))
					{
						BMDSwitcherFairlightAudioSourceId sourceId;
						audioSource->GetId(&sourceId);
						mFairlightAudioSources.insert(std::make_pair(sourceId, audioSource));
						FairlightAudioSourceMonitor *monitor = new FairlightAudioSourceMonitor(self, sourceId);
						audioSource->AddCallback(monitor);
						mMonitors.push_back(monitor);
						mFairlightAudioSourceMonitors.insert(std::make_pair(sourceId, monitor));
					}
					audioSourceIterator->Release();
					audioSourceIterator = NULL;
				}
				else
				{
					[appDel logMessage:[NSString stringWithFormat:@"[Debug] Could not create IBMDSwitcherFairlightAudioSourceIterator iterator. code: %d", HRESULT_CODE(result)]];
				}
			}
			audioInputIterator->Release();
			audioInputIterator = NULL;
		}
		else
		{
			[appDel logMessage:[NSString stringWithFormat:@"[Debug] Could not create IBMDSwitcherFairlightAudioInputIterator iterator. code: %d", HRESULT_CODE(result)]];
		}
	}
	else
	{
		[appDel logMessage:@"[Debug] Could not get IBMDSwitcherFairlightAudioMixer interface (If your switcher does not support Fairlight audio, you can ignore this)"];
	}
	
	// Hyperdeck Setup
	IBMDSwitcherHyperDeckIterator* hyperDeckIterator = NULL;
	if (SUCCEEDED(mSwitcher->CreateIterator(IID_IBMDSwitcherHyperDeckIterator, (void**)&hyperDeckIterator)))
	{
		IBMDSwitcherHyperDeck* hyperdeck = NULL;
		while (S_OK == hyperDeckIterator->Next(&hyperdeck))
		{
			BMDSwitcherHyperDeckId hyperdeckId;
			hyperdeck->GetId(&hyperdeckId);
			mHyperdecks.insert(std::make_pair(hyperdeckId, hyperdeck));
			HyperDeckMonitor *monitor = new HyperDeckMonitor(self, hyperdeckId);
			hyperdeck->AddCallback(monitor);
			mMonitors.push_back(monitor);
			mHyperdeckMonitors.insert(std::make_pair(hyperdeckId, monitor));
		}
		hyperDeckIterator->Release();
		hyperDeckIterator = NULL;
	}
	else
	{
		[appDel logMessage:[NSString stringWithFormat:@"[Debug] Could not create IBMDSwitcherHyperDeckIterator iterator. code: %d", HRESULT_CODE(result)]];
	}
}

- (void)switcherDisconnected
{

	[self setIsConnected: NO];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		Window* window = (Window *) [[NSApplication sharedApplication] mainWindow];
		[[window outlineView] reloadItem:self];

		AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];
		if (appDel.activity)
			[[NSProcessInfo processInfo] endActivity:appDel.activity];
		
		appDel.activity = nil;
	});
	
	if (outPort != nil)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/led/green"];
		[newMsg addFloat:0.0];
		[outPort sendThisMessage:newMsg];
		newMsg = [OSCMessage createWithAddress:@"/atem/led/red"];
		[newMsg addFloat:1.0];
		[outPort sendThisMessage:newMsg];
	}
	
	[self cleanUpConnection];
	[self connectBMD];
}

- (void)cleanUpConnection
{
	if (mSwitcher)
	{
		mSwitcher->RemoveCallback(mSwitcherMonitor);
		mSwitcher->Release();
		mSwitcher = NULL;
		mSwitcherMonitor = NULL;
	}
	
	if (mMixEffectBlock)
	{
		mMixEffectBlock->RemoveCallback(mMixEffectBlockMonitor);
		mMixEffectBlock->Release();
		mMixEffectBlock = NULL;
		mMixEffectBlockMonitor = NULL;
	}
	
	if (switcherTransitionParameters)
	{
		switcherTransitionParameters->RemoveCallback(mTransitionParametersMonitor);
		switcherTransitionParameters->Release();
		switcherTransitionParameters = NULL;
		mTransitionParametersMonitor = NULL;
	}
	
	for (auto const& it : mInputs)
	{
		it.second->RemoveCallback(mInputMonitors.at(it.first));
		it.second->Release();
	}
	mInputs.clear();
	mInputMonitors.clear();
	
	while (mSwitcherInputAuxList.size())
	{
		mSwitcherInputAuxList.back()->Release();
		mSwitcherInputAuxList.pop_back();
	}
	
	while (keyers.size())
	{
		keyers.back()->Release();
		keyers.back()->RemoveCallback(mUpstreamKeyerMonitor);
		IBMDSwitcherKeyLumaParameters* lumaParams = nil;
		keyers.back()->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		if (lumaParams != nil)
			lumaParams->RemoveCallback(mUpstreamKeyerLumaParametersMonitor);
		IBMDSwitcherKeyChromaParameters* chromaParams = nil;
		keyers.back()->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		if (chromaParams != nil)
			chromaParams->RemoveCallback(mUpstreamKeyerChromaParametersMonitor);
		keyers.pop_back();
		mUpstreamKeyerMonitor = NULL;
		mUpstreamKeyerLumaParametersMonitor = NULL;
		mUpstreamKeyerChromaParametersMonitor = NULL;
	}
	
	while (dsk.size())
	{
		dsk.back()->RemoveCallback(mDownstreamKeyerMonitor);
		dsk.back()->Release();
		dsk.pop_back();
		mDownstreamKeyerMonitor = NULL;
	}
	
	while (mMediaPlayers.size())
	{
		mMediaPlayers.back()->Release();
		mMediaPlayers.pop_back();
	}
	
	if (mMediaPool)
	{
		mMediaPool->Release();
		mMediaPool = NULL;
	}
	
	if (mMacroPool)
	{
		mMacroPool->RemoveCallback(mMacroPoolMonitor);
		mMacroPool->Release();
		mMacroPool = NULL;
		mMacroPoolMonitor = NULL;
	}
	
	while (mSuperSourceBoxes.size())
	{
		mSuperSourceBoxes.back()->Release();
		mSuperSourceBoxes.pop_back();
	}
	
	if (mAudioMixer)
	{
		mAudioMixer->RemoveCallback(mAudioMixerMonitor);
		mAudioMixer->Release();
		mAudioMixer = NULL;
		mAudioMixerMonitor = NULL;
	}
	
	for (auto const& it : mAudioInputs)
	{
		it.second->RemoveCallback(mAudioInputMonitors.at(it.first));
		it.second->Release();
	}
	mAudioInputs.clear();
	mAudioInputMonitors.clear();
	
	if (mFairlightAudioMixer)
	{
		mFairlightAudioMixer->RemoveCallback(mFairlightAudioMixerMonitor);
		mFairlightAudioMixer->Release();
		mFairlightAudioMixer = NULL;
		mFairlightAudioMixerMonitor = NULL;
	}
	
	for (auto const& it : mFairlightAudioSources)
	{
		it.second->RemoveCallback(mFairlightAudioSourceMonitors.at(it.first));
		it.second->Release();
	}
	mFairlightAudioSources.clear();
	mFairlightAudioSourceMonitors.clear();
	
	for (auto const& it : mHyperdecks)
	{
		it.second->RemoveCallback(mHyperdeckMonitors.at(it.first));
		it.second->Release();
	}
	mHyperdecks.clear();
	mHyperdeckMonitors.clear();
	
	mMonitors.clear();
}

- (void)setupMonitors
{
	mSwitcherMonitor = new SwitcherMonitor(self);
	mMonitors.push_back(mSwitcherMonitor);
	mDownstreamKeyerMonitor = new DownstreamKeyerMonitor(self);
	mMonitors.push_back(mDownstreamKeyerMonitor);
	mUpstreamKeyerMonitor = new UpstreamKeyerMonitor(self);
	mMonitors.push_back(mUpstreamKeyerMonitor);
	mUpstreamKeyerLumaParametersMonitor = new UpstreamKeyerLumaParametersMonitor(self);
	mMonitors.push_back(mUpstreamKeyerLumaParametersMonitor);
	mUpstreamKeyerChromaParametersMonitor = new UpstreamKeyerChromaParametersMonitor(self);
	mMonitors.push_back(mUpstreamKeyerChromaParametersMonitor);
	mTransitionParametersMonitor = new TransitionParametersMonitor(self);
	mMonitors.push_back(mTransitionParametersMonitor);
	mMixEffectBlockMonitor = new MixEffectBlockMonitor(self);
	mMonitors.push_back(mMixEffectBlockMonitor);
	mMacroPoolMonitor = new MacroPoolMonitor(self);
	mMonitors.push_back(mMacroPoolMonitor);
	mAudioMixerMonitor = new AudioMixerMonitor(self);
	mMonitors.push_back(mAudioMixerMonitor);
	mFairlightAudioMixerMonitor = new FairlightAudioMixerMonitor(self);
	mMonitors.push_back(mFairlightAudioMixerMonitor);
}

// We run this recursively so that we can get the
// delay from each command, and allow for variable
// wait times between sends
- (void)sendStatus
{
	AppDelegate* appDel = (AppDelegate *) [[NSApplication sharedApplication] delegate];

	if ([self isConnected])
	{
		[self sendEachStatus:0];
	}
	else
	{
		[appDel logMessage:@"Cannot send status - Not connected to switcher"];
	}
}

- (void)sendEachStatus:(int)nextMonitor
{
	if (nextMonitor < mMonitors.size()) {
		int delay = mMonitors[nextMonitor]->sendStatus();
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendEachStatus:nextMonitor+1];
		});
	}
}

- (void)saveChanges
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:self];
	[defaults setObject:encodedObject forKey:[NSString stringWithFormat:@"switcher-%@", self.uid]];
	[defaults synchronize];
}

@end
