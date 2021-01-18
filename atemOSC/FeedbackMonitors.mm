#include "FeedbackMonitors.h"
#import "Switcher.h"
#import "Utilities.h"
#import "Window.h"

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

HRESULT MixEffectBlockMonitor::Notify(BMDSwitcherMixEffectBlockEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherMixEffectBlockEventTypeProgramInputChanged:
			updateProgramButtonSelection();
			break;
		case bmdSwitcherMixEffectBlockEventTypePreviewInputChanged:
			updatePreviewButtonSelection();
			break;
		case bmdSwitcherMixEffectBlockEventTypeInTransitionChanged:
			updateInTransitionState();
			break;
		case bmdSwitcherMixEffectBlockEventTypeTransitionPositionChanged:
			updateSliderPosition();
			break;
		case bmdSwitcherMixEffectBlockEventTypePreviewTransitionChanged:
			updatePreviewTransitionEnabled();
			break;
		case bmdSwitcherMixEffectBlockEventTypeTransitionFramesRemainingChanged:
			break;
		case bmdSwitcherMixEffectBlockEventTypeFadeToBlackFramesRemainingChanged:
			break;
		default:    // ignore other property changes not used for this sample app
			break;
	}
	return S_OK;
}

void MixEffectBlockMonitor::updateProgramButtonSelection() const
{
	BMDSwitcherInputId    programId;
	switcher.mMixEffectBlocks[me_]->GetProgramInput(&programId);
	
	for (auto const& it : switcher.mInputs)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/program/%lld",it.first], me_)];
		if (programId==it.first) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[switcher.outPort sendThisMessage:newMsg];
		
		OSCMessage *newMsg2 = [OSCMessage createWithAddress:getFeedbackAddress(switcher, @"/program", me_)];
		[newMsg2 addInt:(int)it.first];
		[switcher.outPort sendThisMessage:newMsg2];
	}
}

void MixEffectBlockMonitor::updatePreviewButtonSelection() const
{
	BMDSwitcherInputId    previewId;
	switcher.mMixEffectBlocks[me_]->GetPreviewInput(&previewId);
	
	for (auto const& it : switcher.mInputs)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/preview/%lld",it.first], me_)];
		if (previewId==it.first) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[switcher.outPort sendThisMessage:newMsg];
		
		OSCMessage *newMsg2 = [OSCMessage createWithAddress:getFeedbackAddress(switcher, @"/preview", me_)];
		[newMsg2 addInt:(int)it.first];
		[switcher.outPort sendThisMessage:newMsg2];
	}
}

void MixEffectBlockMonitor::updateInTransitionState()
{
	bool inTransition;
	switcher.mMixEffectBlocks[me_]->GetInTransition(&inTransition);
	
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
	switcher.mMixEffectBlocks[me_]->GetTransitionPosition(&position);
	
	// Record when transition passes halfway so we can flip orientation of slider handle at the end of transition
	mCurrentTransitionReachedHalfway_ = (position >= 0.50);
	
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;        // slider handle moving in opposite direction
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, @"/transition/bar", me_)];
	[newMsg addFloat:1.0-sliderPosition/100];
	[switcher.outPort sendThisMessage:newMsg];
}

void MixEffectBlockMonitor::updatePreviewTransitionEnabled() const
{
	bool position;
	switcher.mMixEffectBlocks[me_]->GetPreviewTransition(&position);
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, @"/transition/preview", me_)];
	[newMsg addFloat: position ? 1.0 : 0.0];
	[switcher.outPort sendThisMessage:newMsg];
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
	
	updatePreviewTransitionEnabled();
	
	double position;
	switcher.mMixEffectBlocks[me_]->GetTransitionPosition(&position);
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;
	OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, @"/transition/bar",me_)];
	[newMsg addFloat:1.0-sliderPosition/100];
	[switcher.outPort sendThisMessage:newMsg];

	return 0.2;
}

HRESULT InputMonitor::Notify(BMDSwitcherInputEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherInputEventTypeShortNameChanged:
			updateShortName();
			break;
		case bmdSwitcherInputEventTypeLongNameChanged:
			updateLongName();
			break;
		case bmdSwitcherInputEventTypeAreNamesDefaultChanged:
			updateLongName();
			updateShortName();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

void InputMonitor::updateLongName() const
{
	if (switcher.mInputs.count(inputId_) > 0)
	{
		// Have to delay slightly, otherwise fetch gets old name
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			NSString *name;
			switcher.mInputs[inputId_]->GetLongName((CFStringRef*)&name);
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/input/%lld/long-name", inputId_])];
			[newMsg addString:name];
			[[switcher outPort] sendThisMessage:newMsg];
		});
	}
}

void InputMonitor::updateShortName() const
{
	if (switcher.mInputs.count(inputId_) > 0)
	{
		// Have to delay slightly, otherwise fetch gets old name
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			NSString *name;
			switcher.mInputs[inputId_]->GetShortName((CFStringRef*)&name);
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/input/%lld/short-name", inputId_])];
			[newMsg addString:name];
			[[switcher outPort] sendThisMessage:newMsg];
		});
	}
	
	Window* window = (Window *) [[NSApplication sharedApplication] mainWindow];
	if ([[window connectionView] switcher] == switcher)
	{
		[[window connectionView] loadFromSwitcher:switcher];
		[[window addressesView] loadFromSwitcher:switcher];
	}
}

float InputMonitor::sendStatus() const
{
	updateLongName();
	updateShortName();
	
	return 0.1;
}

// Send OSC messages out when DSK Tie is changed on switcher
void DownstreamKeyerMonitor::updateDSKTie() const
{
	int i = 1;
	for(auto& key : [switcher dsk])
	{
		bool isTied;
		key->GetTie(&isTied);

		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/dsk/%d/tie",i])];
		[newMsg addInt: isTied];
		[switcher.outPort sendThisMessage:newMsg];

		i++;
	}
}

// Send OSC messages out when DSK On Air is changed on switcher
void DownstreamKeyerMonitor::updateDSKOnAir() const
{
	int i = 1;
	for(auto& key : [switcher dsk])
	{
		bool isOnAir;
		key->GetOnAir(&isOnAir);

		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/dsk/%d/on-air",i])];
		[newMsg addInt: isOnAir];
		[switcher.outPort sendThisMessage:newMsg];

		i++;
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

// Send OSC messages out when DSK On Air is changed on switcher
void UpstreamKeyerMonitor::updateUSKOnAir() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		bool isOnAir;
		key->GetOnAir(&isOnAir);

		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/on-air",i], me_)];
		[newMsg addInt: isOnAir];
		[switcher.outPort sendThisMessage:newMsg];

		i++;
	}
}

void UpstreamKeyerMonitor::updateUSKInputFill() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		BMDSwitcherInputId inputId;
		key->GetInputFill(&inputId);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/source/fill",i++], me_)];
		[newMsg addInt: static_cast<int>(inputId)];
		[switcher.outPort sendThisMessage:newMsg];
	}
}

void UpstreamKeyerMonitor::updateUSKInputCut() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		BMDSwitcherInputId inputId;
		key->GetInputCut(&inputId);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/source/cut",i++], me_)];
		[newMsg addInt: static_cast<int>(inputId)];
		[switcher.outPort sendThisMessage:newMsg];
	}
}

HRESULT UpstreamKeyerMonitor::Notify(BMDSwitcherKeyEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherKeyEventTypeOnAirChanged:
			updateUSKOnAir();
			break;
		case bmdSwitcherKeyEventTypeInputCutChanged:
			updateUSKInputCut();
			break;
		case bmdSwitcherKeyEventTypeInputFillChanged:
			updateUSKInputFill();
			break;
		case bmdSwitcherKeyEventTypeTypeChanged:
			updateUSKType();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

void UpstreamKeyerMonitor::updateUSKType() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		BMDSwitcherKeyType type;
		key->GetType(&type);
		
		NSString *typeStr;
		if (type == bmdSwitcherKeyTypeLuma)
			typeStr = @"luma";
		if (type == bmdSwitcherKeyTypeChroma)
			typeStr = @"chroma";
		if (type == bmdSwitcherKeyTypePattern)
			typeStr = @"pattern";
		if (type == bmdSwitcherKeyTypeDVE)
			typeStr = @"dve";
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/type",i], me_)];
		[newMsg addString: typeStr];
		[switcher.outPort sendThisMessage:newMsg];
		
		// Support for legacy clients like TouchOSC
		OSCMessage *newMsg2 = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/type/%@",i++, typeStr], me_)];
		[newMsg2 addFloat: 1.0];
		[switcher.outPort sendThisMessage:newMsg2];
	}
}


float UpstreamKeyerMonitor::sendStatus() const
{
	updateUSKOnAir();
	updateUSKInputCut();
	updateUSKInputFill();
	updateUSKType();

	return 0.4;
}

HRESULT UpstreamKeyerLumaParametersMonitor::Notify(BMDSwitcherKeyLumaParametersEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherKeyLumaParametersEventTypePreMultipliedChanged:
			updateUSKLumaPreMultipliedParameter();
			break;
		case bmdSwitcherKeyLumaParametersEventTypeClipChanged:
			updateUSKLumaClipParameter();
			break;
		case bmdSwitcherKeyLumaParametersEventTypeGainChanged:
			updateUSKLumaGainParameter();
			break;
		case bmdSwitcherKeyLumaParametersEventTypeInverseChanged:
			updateUSKLumaInverseParameter();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

void UpstreamKeyerLumaParametersMonitor::updateUSKLumaClipParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			double clip;
			lumaParams->GetClip(&clip);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/luma/clip",i++], me_)];
			[newMsg addFloat:clip];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaGainParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			double gain;
			lumaParams->GetGain(&gain);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/luma/gain",i++], me_)];
			[newMsg addFloat:gain];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaPreMultipliedParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			bool preMultiplied;
			lumaParams->GetPreMultiplied(&preMultiplied);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/luma/pre-multiplied",i++], me_)];
			[newMsg addBOOL:preMultiplied];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaInverseParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			bool inverse;
			lumaParams->GetInverse(&inverse);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/luma/inverse",i++], me_)];
			[newMsg addBOOL:inverse];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}

float UpstreamKeyerLumaParametersMonitor::sendStatus() const
{
	updateUSKLumaClipParameter();
	updateUSKLumaGainParameter();
	updateUSKLumaPreMultipliedParameter();
	updateUSKLumaInverseParameter();
	
	return 0.4;
}

HRESULT UpstreamKeyerChromaParametersMonitor::Notify(BMDSwitcherKeyChromaParametersEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherKeyChromaParametersEventTypeHueChanged:
			updateUSKChromaHueParameter();
			break;
		case bmdSwitcherKeyChromaParametersEventTypeGainChanged:
			updateUSKChromaGainParameter();
			break;
		case bmdSwitcherKeyChromaParametersEventTypeYSuppressChanged:
			updateUSKChromaYSuppressParameter();
			break;
		case bmdSwitcherKeyChromaParametersEventTypeLiftChanged:
			updateUSKChromaLiftParameter();
			break;
		case bmdSwitcherKeyChromaParametersEventTypeNarrowChanged:
			updateUSKChromaNarrowParameter();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	return S_OK;
}

void UpstreamKeyerChromaParametersMonitor::updateUSKChromaHueParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double hue;
			chromaParams->GetHue(&hue);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/hue",i++], me_)];
			[newMsg addFloat:hue];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaGainParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double gain;
			chromaParams->GetGain(&gain);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/gain",i++], me_)];
			[newMsg addFloat:gain];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaYSuppressParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double ySuppress;
			chromaParams->GetYSuppress(&ySuppress);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/y-suppress",i++], me_)];
			[newMsg addFloat:ySuppress];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaLiftParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double lift;
			chromaParams->GetLift(&lift);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/lift",i++], me_)];
			[newMsg addFloat:lift];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaNarrowParameter() const
{
	int i = 1;
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for(auto& key : keyers)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			bool narrow;
			chromaParams->GetNarrow(&narrow);
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/narrow",i++], me_)];
			[newMsg addBOOL:narrow];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}

float UpstreamKeyerChromaParametersMonitor::sendStatus() const
{
	updateUSKChromaNarrowParameter();
	updateUSKChromaYSuppressParameter();
	updateUSKChromaGainParameter();
	updateUSKChromaHueParameter();
	updateUSKChromaLiftParameter();
	
	return 0.4;
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
	IBMDSwitcherTransitionParameters* mTransitionParameters=NULL;
	if (SUCCEEDED(switcher.mMixEffectBlocks[me_]->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void**)&mTransitionParameters)))
	{
		uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };

		uint32_t currentTransitionSelection;
		mTransitionParameters->GetNextTransitionSelection(&currentTransitionSelection);

		for (int i = 0; i <= ((int) switcher.keyers.size()); i++) {
			uint32_t requestedTransitionSelection = transitionSelections[i];
			
			OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/usk/%d/tie",i], me_)];
			[newMsg addInt: ((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
			[switcher.outPort sendThisMessage:newMsg];
		}
	}
}

float TransitionParametersMonitor::sendStatus() const
{
	updateTransitionParameters();

	return 0.12;
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
	NSString *name = getNameOfMacro(switcher, index);
	if (![name isEqualToString:@""]) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/macros/%d/name", index])];
		[newMsg addString:name];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateMacroDescription(int index) const
{
	NSString *description = getDescriptionOfMacro(switcher, index);
	if (![description isEqualToString:@""]) {
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/macros/%d/description", index])];
		[newMsg addString:description];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateNumberOfMacros() const
{
	uint32_t maxNumberOfMacros = getMaxNumberOfMacros(switcher);
	if (maxNumberOfMacros > 0)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/macros/max-number"];
		[newMsg addInt:(int)maxNumberOfMacros];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void MacroPoolMonitor::updateMacroValidity(int index) const
{
	int value = isMacroValid(switcher, index);
	OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/macros/%d/is-valid", index])];
	[newMsg addInt:(int)value];
	[[switcher outPort] sendThisMessage:newMsg];
}

float MacroPoolMonitor::sendStatus() const
{
	uint32_t maxNumberOfMacros = getMaxNumberOfMacros(switcher);
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
		[switcher switcherDisconnected:YES];
		[switcher logMessage:@"[Debug] Switcher time code changed"];
	}
	else if (eventType == bmdSwitcherEventTypeTimeCodeChanged)
		[switcher logMessage:@"[Debug] Switcher time code changed"];
	else
		[switcher logMessage:[NSString stringWithFormat:@"[Debug] Switcher unknown event occurred: %d", eventType]];
	return S_OK;
}

float SwitcherMonitor::sendStatus() const
{
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/led/green"];
	[newMsg addFloat:[switcher isConnected] ? 1.0 : 0.0];
	[[switcher outPort] sendThisMessage:newMsg];
	newMsg = [OSCMessage createWithAddress:@"/led/red"];
	[newMsg addFloat:[switcher isConnected] ? 0.0 : 1.0];
	[[switcher outPort] sendThisMessage:newMsg];

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
	if (switcher.mAudioInputs.count(inputId_) > 0)
	{
		double gain;
		switcher.mAudioInputs[inputId_]->GetGain(&gain);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/audio/input/%lld/gain", inputId_])];
		[newMsg addFloat:(float)gain];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void AudioInputMonitor::updateBalance() const
{
	if (switcher.mAudioInputs.count(inputId_) > 0)
	{
		double balance;
		switcher.mAudioInputs[inputId_]->GetBalance(&balance);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/audio/input/%lld/balance", inputId_])];
		[newMsg addFloat:(float)balance];
		[[switcher outPort] sendThisMessage:newMsg];
	}
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
	if (switcher.mAudioMixer != nil)
	{
		double gain;
		switcher.mAudioMixer->GetProgramOutGain(&gain);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/audio/output/gain"];
		[newMsg addFloat:(float)gain];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void AudioMixerMonitor::updateBalance() const
{
	if (switcher.mAudioMixer != nil)
	{
		double balance;
		switcher.mAudioMixer->GetProgramOutBalance(&balance);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/audio/output/balance"];
		[newMsg addFloat:(float)balance];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

float AudioMixerMonitor::sendStatus() const
{
	updateGain();
	updateBalance();

	return 0.02;
}

HRESULT STDMETHODCALLTYPE FairlightAudioSourceMonitor::Notify (BMDSwitcherFairlightAudioSourceEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherFairlightAudioSourceEventTypeFaderGainChanged:
			updateFaderGain();
			break;
		case bmdSwitcherFairlightAudioSourceEventTypePanChanged:
			updatePan();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	
	return S_OK;
}

HRESULT STDMETHODCALLTYPE FairlightAudioSourceMonitor::OutputLevelNotification (uint32_t numLevels, const double* levels, uint32_t numPeakLevels, const double* peakLevels)
{
	return S_OK;
}

void FairlightAudioSourceMonitor::updateFaderGain() const
{
	if (switcher.mFairlightAudioSources.count(sourceId_) > 0)
	{
		double gain;
		switcher.mFairlightAudioSources[sourceId_]->GetFaderGain(&gain);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/fairlight-audio/source/%lld/gain", sourceId_])];
		[newMsg addFloat:(float)gain];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void FairlightAudioSourceMonitor::updatePan() const
{
	if (switcher.mFairlightAudioSources.count(sourceId_) > 0)
	{
		double pan;
		switcher.mFairlightAudioSources[sourceId_]->GetPan(&pan);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/fairlight-audio/source/%lld/pan", sourceId_])];
		[newMsg addFloat:(float)pan];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

float FairlightAudioSourceMonitor::sendStatus() const
{
	updateFaderGain();
	updatePan();

	return 0.02;
}


HRESULT STDMETHODCALLTYPE FairlightAudioMixerMonitor::Notify (BMDSwitcherFairlightAudioMixerEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherFairlightAudioMixerEventTypeMasterOutFaderGainChanged:
			updateGain();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	
	return S_OK;
}

HRESULT STDMETHODCALLTYPE FairlightAudioMixerMonitor::MasterOutLevelNotification (uint32_t numLevels, const double* levels, uint32_t numPeakLevels, const double* peakLevels)
{
	return S_OK;
}

void FairlightAudioMixerMonitor::updateGain() const
{
	if (switcher.mFairlightAudioMixer != nil)
	{
		double gain;
		switcher.mFairlightAudioMixer->GetMasterOutFaderGain(&gain);
		OSCMessage *newMsg = [OSCMessage createWithAddress:@"/fairlight-audio/output/gain"];
		[newMsg addFloat:(float)gain];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

float FairlightAudioMixerMonitor::sendStatus() const
{
	updateGain();

	return 0.01;
}



float HyperDeckMonitor::sendStatus() const
{
	updateCurrentClip();
	updateCurrentClipTime();
	updateCurrentTimelineTime();
	updatePlayerState();
	
	return 0.03;
}

HRESULT HyperDeckMonitor::Notify (BMDSwitcherHyperDeckEventType eventType)
{
	switch (eventType)
	{
		case bmdSwitcherHyperDeckEventTypeCurrentClipChanged:
			updateCurrentClip();
			break;
		case bmdSwitcherHyperDeckEventTypeCurrentClipTimeChanged:
			updateCurrentClipTime();
			break;
		case bmdSwitcherHyperDeckEventTypeCurrentTimelineTimeChanged:
			updateCurrentTimelineTime();
			break;
		case bmdSwitcherHyperDeckEventTypePlayerStateChanged:
			updatePlayerState();
			break;
		default:
			// ignore other property changes not used for this app
			break;
	}
	
	return S_OK;
}

void HyperDeckMonitor::updateCurrentClip() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		BMDSwitcherHyperDeckClipId clipId;
		switcher.mHyperdecks[hyperdeckId_]->GetCurrentClip(&clipId);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/clip", hyperdeckId_])];
		[newMsg addInt:(int)clipId+1];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void HyperDeckMonitor::updateCurrentClipTime() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		uint16_t hours;
		uint8_t minutes, seconds, frames;
		switcher.mHyperdecks[hyperdeckId_]->GetCurrentClipTime(&hours, &minutes, &seconds, &frames);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/clip-time", hyperdeckId_])];
		[newMsg addString:[NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds]];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void HyperDeckMonitor::updateCurrentTimelineTime() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		uint16_t hours;
		uint8_t minutes, seconds, frames;
		switcher.mHyperdecks[hyperdeckId_]->GetCurrentTimelineTime(&hours, &minutes, &seconds, &frames);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/timeline-time", hyperdeckId_])];
		[newMsg addString:[NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds]];
		[[switcher outPort] sendThisMessage:newMsg];
	}
}

void HyperDeckMonitor::updatePlayerState() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		BMDSwitcherHyperDeckPlayerState state;
		switcher.mHyperdecks[hyperdeckId_]->GetPlayerState(&state);
		OSCMessage *newMsg = [OSCMessage createWithAddress:getFeedbackAddress(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/state", hyperdeckId_])];
		switch (state)
		{
			case bmdSwitcherHyperDeckStateIdle: [newMsg addString:@"idle"]; break;
			case bmdSwitcherHyperDeckStatePlay: [newMsg addString:@"play"]; break;
			case bmdSwitcherHyperDeckStateRecord: [newMsg addString:@"record"]; break;
			case bmdSwitcherHyperDeckStateShuttle: [newMsg addString:@"shuttle"]; break;
			case bmdSwitcherHyperDeckStateUnknown: [newMsg addString:@"unknown"]; break;
		}
		[[switcher outPort] sendThisMessage:newMsg];
	}
}
