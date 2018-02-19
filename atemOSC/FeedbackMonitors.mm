#include "FeedbackMonitors.h"
#import "AppDelegate.h"
#import "Utilities.h"

static inline bool    operator== (const REFIID& iid1, const REFIID& iid2)
{
	return CFEqual(&iid1, &iid2);
}

template<class T>
HRESULT STDMETHODCALLTYPE GenericMonitor<T>::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;
	
	if (iid == IID_IBMDSwitcherMixEffectBlockCallback)
	{
		*ppv = static_cast<T*>(this);
		AddRef();
		return S_OK;
	}
	
	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<T*>(this);
		AddRef();
		return S_OK;
	}
	
	*ppv = NULL;
	return E_NOINTERFACE;
}

template<class T>
ULONG STDMETHODCALLTYPE GenericMonitor<T>::AddRef(void)
{
	return ::OSAtomicIncrement32(&mRefCount);
}

template<class T>
ULONG STDMETHODCALLTYPE GenericMonitor<T>::Release(void)
{
	int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT MixEffectBlockMonitor::PropertyChanged(BMDSwitcherMixEffectBlockPropertyId propertyId)
{
	switch (propertyId)
	{
		case bmdSwitcherMixEffectBlockPropertyIdProgramInput:
			updateProgramButtonSelection();
			break;
		case bmdSwitcherMixEffectBlockPropertyIdPreviewInput:
			updatePreviewButtonSelection();
			break;
		case bmdSwitcherMixEffectBlockPropertyIdInTransition:
			updateInTransitionState();
			break;
		case bmdSwitcherMixEffectBlockPropertyIdTransitionPosition:
			updateSliderPosition();
			break;
		case bmdSwitcherMixEffectBlockPropertyIdTransitionFramesRemaining:
			break;
		case bmdSwitcherMixEffectBlockPropertyIdFadeToBlackFramesRemaining:
			break;
		default:    // ignore other property changes not used for this sample app
			break;
	}
	return S_OK;
}

void MixEffectBlockMonitor::updateProgramButtonSelection() const
{
	BMDSwitcherInputId    programId;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetInt(bmdSwitcherMixEffectBlockPropertyIdProgramInput, &programId);
	
	for (int i = 0;i<=12;i++) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/program/%d",i]];
		if (programId==i) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

void MixEffectBlockMonitor::updatePreviewButtonSelection() const
{
	BMDSwitcherInputId    previewId;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetInt(bmdSwitcherMixEffectBlockPropertyIdPreviewInput, &previewId);
	
	for (int i = 0;i<=12;i++) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/preview/%d",i]];
		if (previewId==i) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

void MixEffectBlockMonitor::updateInTransitionState()
{
	bool inTransition;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetFlag(bmdSwitcherMixEffectBlockPropertyIdInTransition, &inTransition);
	
	if (inTransition == false)
	{
		// Toggle the starting orientation of slider handle if a transition has passed through halfway
		if (mCurrentTransitionReachedHalfway_)
		{
			mMoveSliderDownwards = ! mMoveSliderDownwards;
			updateSliderPosition();
		}
		
		mCurrentTransitionReachedHalfway_ = false;
	}
}

void MixEffectBlockMonitor::updateSliderPosition()
{
	double position;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetFloat(bmdSwitcherMixEffectBlockPropertyIdTransitionPosition, &position);
	
	// Record when transition passes halfway so we can flip orientation of slider handle at the end of transition
	mCurrentTransitionReachedHalfway_ = (position >= 0.50);
	
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;        // slider handle moving in opposite direction
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/transition/bar"];
	[newMsg addFloat:1.0-sliderPosition/100];
	[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
}

float MixEffectBlockMonitor::sendStatus() const
{
	// Sending both program and preview at the same time causes a race condition, TouchOSC can't handle
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		updatePreviewButtonSelection();
	});

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		updateProgramButtonSelection();
	});
	
	double position;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetFloat(bmdSwitcherMixEffectBlockPropertyIdTransitionPosition, &position);
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/transition/bar"];
	[newMsg addFloat:1.0-sliderPosition/100];
	[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];

	return 0.2;
}

// Send OSC messages out when DSK Tie is changed on switcher
void DownstreamKeyerMonitor::updateDSKTie() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel dsk])
	{
		bool isTied;
		key->GetTie(&isTied);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/set-tie/%d",i++]];
		[newMsg addInt: isTied];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

// Send OSC messages out when DSK On Air is changed on switcher
void DownstreamKeyerMonitor::updateDSKOnAir() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel dsk])
	{
		bool isOnAir;
		key->GetOnAir(&isOnAir);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/on-air/%d",i++]];
		[newMsg addInt: isOnAir];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

HRESULT DownstreamKeyerMonitor::Notify(BMDSwitcherDownstreamKeyEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherDownstreamKeyEventTypeTieChanged:
			updateDSKTie();
			break;
		case bmdSwitcherDownstreamKeyEventTypeOnAirChanged:
			updateDSKOnAir();
			break;
		case bmdSwitcherDownstreamKeyEventTypeIsTransitioningChanged:
			// Might want to do something with this down the road
			break;
		case bmdSwitcherDownstreamKeyEventTypeIsAutoTransitioningChanged:
			// Might want to do something with this down the road
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

float DownstreamKeyerMonitor::sendStatus() const
{
	updateDSKTie();
	updateDSKOnAir();

	return 0.1;
}

HRESULT TransitionParametersMonitor::Notify(BMDSwitcherTransitionParametersEventType eventType)
{
	
	switch (eventType)
	{
		case bmdSwitcherTransitionParametersEventTypeNextTransitionSelectionChanged:
			updateTransitionParameters();
			break;
		case bmdSwitcherTransitionParametersEventTypeTransitionSelectionChanged:
			updateTransitionParameters();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

// Send OSC messages out when USK Tie is changed on switcher
void TransitionParametersMonitor::updateTransitionParameters() const
{
	uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };
	
	uint32_t currentTransitionSelection;
	static_cast<AppDelegate *>(appDel).switcherTransitionParameters->GetNextTransitionSelection(&currentTransitionSelection);
	
	for (int i = 0; i <= ((int) reinterpret_cast<AppDelegate *>(appDel).keyers.size()); i++) {
		uint32_t requestedTransitionSelection = transitionSelections[i];
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/nextusk/%d",i]];
		[newMsg addInt: ((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

float TransitionParametersMonitor::sendStatus() const
{
	updateTransitionParameters();

	return 0.08;
}

HRESULT MacroPoolMonitor::Notify (BMDSwitcherMacroPoolEventType eventType, uint32_t index, IBMDSwitcherTransferMacro* macroTransfer)
{
	
	switch (eventType)
	{
		case bmdSwitcherMacroPoolEventTypeNameChanged:
			updateMacroName(index);
			break;
		case bmdSwitcherMacroPoolEventTypeDescriptionChanged:
			updateMacroDescription(index);
			break;
		case bmdSwitcherMacroPoolEventTypeValidChanged:
			updateMacroValidity(index);
			updateNumberOfMacros();
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

void MacroPoolMonitor::updateMacroName(int index) const
{
	NSString *name = getNameOfMacro(index);
	if (![name isEqualToString:@""]) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/macros/%d/name", index]];
		[newMsg addString:name];
		[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateMacroDescription(int index) const
{
	NSString *description = getDescriptionOfMacro(index);
	if (![description isEqualToString:@""]) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/macros/%d/description", index]];
		[newMsg addString:description];
		[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateNumberOfMacros() const
{
	uint32_t maxNumberOfMacros = getMaxNumberOfMacros();
	if (maxNumberOfMacros > 0)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/macros/max-number"];
		[newMsg addInt:(int)maxNumberOfMacros];
		[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateMacroValidity(int index) const
{
	int value = isMacroValid(index);
	OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/macros/%d/is-valid", index]];
	[newMsg addInt:(int)value];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

float MacroPoolMonitor::sendStatus() const
{
	uint32_t maxNumberOfMacros = getMaxNumberOfMacros();
	for (int i = 0; i < maxNumberOfMacros; i++) {
		updateMacroValidity(i);
		updateMacroName(i);
		updateMacroDescription(i);
	}

	return 0.1;
}

HRESULT STDMETHODCALLTYPE SwitcherMonitor::Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode)
{
	if (eventType == bmdSwitcherEventTypeDisconnected)
	{
		[(AppDelegate *)appDel performSelectorOnMainThread:@selector(switcherDisconnected) withObject:nil waitUntilDone:YES];
	}
	return S_OK;
}

float SwitcherMonitor::sendStatus() const
{
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/led/green"];
	[newMsg addFloat:[static_cast<AppDelegate *>(appDel) isConnectedToATEM] ? 1.0 : 0.0];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	newMsg = [OSCMessage createWithAddress:@"/atem/led/red"];
	[newMsg addFloat:[static_cast<AppDelegate *>(appDel) isConnectedToATEM] ? 0.0 : 1.0];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];

	return 0.01;
}

HRESULT STDMETHODCALLTYPE AudioInputMonitor::Notify (BMDSwitcherAudioInputEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherAudioInputEventTypeGainChanged:
			updateGain();
			break;
		case bmdSwitcherAudioInputEventTypeBalanceChanged:
			updateBalance();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	
	return S_OK;
}

HRESULT STDMETHODCALLTYPE AudioInputMonitor::LevelNotification (double left, double right, double peakLeft, double peakRight)
{
	return S_OK;
}

void AudioInputMonitor::updateGain() const
{
	double gain;
	static_cast<AppDelegate *>(appDel).mAudioInputs[index_]->GetGain(&gain);
	OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/audio/input/%d/gain", index_+1]];
	[newMsg addFloat:(float)gain];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

void AudioInputMonitor::updateBalance() const
{
	double balance;
	static_cast<AppDelegate *>(appDel).mAudioInputs[index_]->GetBalance(&balance);
	OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/audio/input/%d/balance", index_+1]];
	[newMsg addFloat:(float)balance];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

float AudioInputMonitor::sendStatus() const
{
	updateGain();
	updateBalance();

	return 0.02;
}


HRESULT STDMETHODCALLTYPE AudioMixerMonitor::Notify (BMDSwitcherAudioMixerEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherAudioMixerEventTypeProgramOutGainChanged:
			updateGain();
			break;
		case bmdSwitcherAudioMixerEventTypeProgramOutBalanceChanged:
			updateBalance();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	
	return S_OK;
}

HRESULT STDMETHODCALLTYPE AudioMixerMonitor::ProgramOutLevelNotification (double left, double right, double peakLeft, double peakRight)
{
	return S_OK;
}

void AudioMixerMonitor::updateGain() const
{
	double gain;
	static_cast<AppDelegate *>(appDel).mAudioMixer->GetProgramOutGain(&gain);
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/audio/output/gain"];
	[newMsg addFloat:(float)gain];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

void AudioMixerMonitor::updateBalance() const
{
	double balance;
	static_cast<AppDelegate *>(appDel).mAudioMixer->GetProgramOutBalance(&balance);
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/audio/output/balance"];
	[newMsg addFloat:(float)balance];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

float AudioMixerMonitor::sendStatus() const
{
	updateGain();
	updateBalance();

	return 0.02;
}



