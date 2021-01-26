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
	
	sendFeedbackMessage(switcher, @"/program", [OSCValue createWithInt:(int)programId], me_);
	
	for (auto const& it : switcher.mInputs)
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/program/%lld",it.first], [OSCValue createWithFloat: programId==it.first ? 1.0 : 0.0], me_);
}

void MixEffectBlockMonitor::updatePreviewButtonSelection() const
{
	BMDSwitcherInputId    previewId;
	switcher.mMixEffectBlocks[me_]->GetPreviewInput(&previewId);
	
	sendFeedbackMessage(switcher, @"/preview", [OSCValue createWithInt:(int)previewId], me_);
	
	for (auto const& it : switcher.mInputs)
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/preview/%lld",it.first], [OSCValue createWithFloat: previewId==it.first ? 1.0 : 0.0], me_);
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
	
	sendFeedbackMessage(switcher, @"/transition/bar", [OSCValue createWithFloat:1.0-sliderPosition/100], me_);
}

void MixEffectBlockMonitor::updatePreviewTransitionEnabled() const
{
	bool position;
	switcher.mMixEffectBlocks[me_]->GetPreviewTransition(&position);
	sendFeedbackMessage(switcher, @"/transition/preview", [OSCValue createWithFloat: position ? 1.0 : 0.0], me_);
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
	sendFeedbackMessage(switcher, @"/transition/bar", [OSCValue createWithFloat:1.0-sliderPosition/100], me_);

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
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/input/%lld/long-name", inputId_], [OSCValue createWithString:name]);
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
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/input/%lld/short-name", inputId_], [OSCValue createWithString:name]);

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
	for (int i = 0; i < [switcher dsk].size(); i++)
	{
		bool isTied;
		[switcher dsk][i]->GetTie(&isTied);

		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/dsk/%d/tie",i+1], [OSCValue createWithInt:isTied]);
	}
}

// Send OSC messages out when DSK On Air is changed on switcher
void DownstreamKeyerMonitor::updateDSKOnAir() const
{
	for (int i = 0; i < [switcher dsk].size(); i++)
	{
		bool isOnAir;
		[switcher dsk][i]->GetOnAir(&isOnAir);

		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/dsk/%d/on-air",i+1], [OSCValue createWithInt:isOnAir]);
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
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		bool isOnAir;
		keyers[i]->GetOnAir(&isOnAir);

		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/on-air",i+1], [OSCValue createWithInt:isOnAir]);
	}
}

void UpstreamKeyerMonitor::updateUSKInputFill() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		BMDSwitcherInputId inputId;
		keyers[i]->GetInputFill(&inputId);
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/source/fill",i+1], [OSCValue createWithInt:(int)inputId], me_);
	}
}

void UpstreamKeyerMonitor::updateUSKInputCut() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		BMDSwitcherInputId inputId;
		keyers[i]->GetInputCut(&inputId);
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/source/cut",i+1], [OSCValue createWithInt:(int)inputId], me_);
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
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		BMDSwitcherKeyType type;
		keyers[i]->GetType(&type);
		
		NSString *typeStr;
		if (type == bmdSwitcherKeyTypeLuma)
			typeStr = @"luma";
		if (type == bmdSwitcherKeyTypeChroma)
			typeStr = @"chroma";
		if (type == bmdSwitcherKeyTypePattern)
			typeStr = @"pattern";
		if (type == bmdSwitcherKeyTypeDVE)
			typeStr = @"dve";
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/type",i+1], [OSCValue createWithString:typeStr], me_);
		
		// Support for legacy clients like TouchOSC
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/type/%@",i+1, typeStr], [OSCValue createWithFloat:1.0], me_);
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
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			double clip;
			lumaParams->GetClip(&clip);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/luma/clip",i+1], [OSCValue createWithFloat:clip], me_);
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaGainParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			double gain;
			lumaParams->GetGain(&gain);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/luma/gain",i+1], [OSCValue createWithFloat:gain], me_);
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaPreMultipliedParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			bool preMultiplied;
			lumaParams->GetPreMultiplied(&preMultiplied);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/luma/pre-multiplied",i+1], [OSCValue createWithBool:preMultiplied], me_);
		}
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaInverseParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams)))
		{
			bool inverse;
			lumaParams->GetInverse(&inverse);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/luma/inverse",i+1], [OSCValue createWithBool:inverse], me_);
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
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double hue;
			chromaParams->GetHue(&hue);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/hue",i+1], [OSCValue createWithFloat:hue], me_);
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaGainParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double gain;
			chromaParams->GetGain(&gain);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/gain",i+1], [OSCValue createWithFloat:gain], me_);
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaYSuppressParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double ySuppress;
			chromaParams->GetYSuppress(&ySuppress);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/y-suppress",i+1], [OSCValue createWithFloat:ySuppress], me_);
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaLiftParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			double lift;
			chromaParams->GetLift(&lift);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/lift",i+1], [OSCValue createWithFloat:lift], me_);
		}
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaNarrowParameter() const
{
	std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
	for (int i = 0; i < keyers.size(); i++)
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		if (SUCCEEDED(keyers[i]->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams)))
		{
			bool narrow;
			chromaParams->GetNarrow(&narrow);
			
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/chroma/narrow",i+1], [OSCValue createWithBool:narrow], me_);
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

		std::vector<IBMDSwitcherKey*> keyers = [switcher keyers][me_];
		for (int i = 0; i <= keyers.size(); i++)
		{
			uint32_t requestedTransitionSelection = transitionSelections[i];
		
			sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/usk/%d/tie", i], [OSCValue createWithInt:((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)], me_);
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
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/macros/%d/name", index], [OSCValue createWithString:name]);
	}
}

void MacroPoolMonitor::updateMacroDescription(int index) const
{
	NSString *description = getDescriptionOfMacro(switcher, index);
	if (![description isEqualToString:@""]) {
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/macros/%d/description", index], [OSCValue createWithString:description]);
	}
}

void MacroPoolMonitor::updateNumberOfMacros() const
{
	uint32_t maxNumberOfMacros = getMaxNumberOfMacros(switcher);
	if (maxNumberOfMacros > 0)
	{
		sendFeedbackMessage(switcher, @"/macros/max-number", [OSCValue createWithInt:(int)maxNumberOfMacros]);
	}
}

void MacroPoolMonitor::updateMacroValidity(int index) const
{
	int value = isMacroValid(switcher, index);
	sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/macros/%d/is-valid", index], [OSCValue createWithInt:(int)value]);

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
		[switcher logMessage:@"Switcher disconnected"];
	}
	// TimeCodeChanged happens very frequently, don't want to clutter visible logs
	else if (eventType == bmdSwitcherEventTypeTimeCodeChanged)
		NSLog(@"[Debug] Switcher time code changed");
	else
		[switcher logMessage:[NSString stringWithFormat:@"[Debug] Switcher unknown event occurred: %d", eventType]];
	return S_OK;
}

float SwitcherMonitor::sendStatus() const
{
	sendFeedbackMessage(switcher, @"/led/green", [OSCValue createWithFloat:[switcher isConnected] ? 1.0 : 0.0]);
	sendFeedbackMessage(switcher, @"/led/red", [OSCValue createWithFloat:[switcher isConnected] ? 0.0 : 1.0]);

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
		case bmdSwitcherAudioInputEventTypeMixOptionChanged:
			updateMixOption();
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
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/gain", inputId_], [OSCValue createWithFloat:(float)gain]);
	}
}

void AudioInputMonitor::updateBalance() const
{
	if (switcher.mAudioInputs.count(inputId_) > 0)
	{
		double balance;
		switcher.mAudioInputs[inputId_]->GetBalance(&balance);
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/balance", inputId_], [OSCValue createWithFloat:(float)balance]);
	}
}

void AudioInputMonitor::updateMixOption() const
{
	if (switcher.mAudioInputs.count(inputId_) > 0)
	{
		BMDSwitcherAudioMixOption mix;
		switcher.mAudioInputs[inputId_]->GetMixOption(&mix);
		
		NSString *mixOptionString = @"";
		if (mix == bmdSwitcherAudioMixOptionAudioFollowVideo)
			mixOptionString = @"afv";
		else if (mix == bmdSwitcherAudioMixOptionOn)
			mixOptionString = @"on";
		else if (mix == bmdSwitcherAudioMixOptionOff)
			mixOptionString = @"off";

		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/mix", inputId_], [OSCValue createWithString:mixOptionString]);
	}
}

float AudioInputMonitor::sendStatus() const
{
	updateGain();
	updateBalance();
	updateMixOption();

	return 0.03;
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
		sendFeedbackMessage(switcher, @"/audio/output/gain", [OSCValue createWithFloat:(float)gain]);
	}
}

void AudioMixerMonitor::updateBalance() const
{
	if (switcher.mAudioMixer != nil)
	{
		double balance;
		switcher.mAudioMixer->GetProgramOutBalance(&balance);
		sendFeedbackMessage(switcher, @"/audio/output/balance", [OSCValue createWithFloat:(float)balance]);
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
		case bmdSwitcherFairlightAudioSourceEventTypeMixOptionChanged:
			updateMixOption();
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
	if (switcher.mFairlightAudioSources.count(inputId_) > 0)
	{
		double gain;
		switcher.mFairlightAudioSources[inputId_][sourceId_]->GetFaderGain(&gain);
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/gain", inputId_], [OSCValue createWithFloat:(float)gain]);
		
		NSString *address = @"/audio/input/%lld/left/gain";
		if (sourceId_ == switcher.mFairlightAudioSources[inputId_].end()->first)
			address = @"/audio/input/%lld/right/gain";
		sendFeedbackMessage(switcher, [NSString stringWithFormat:address, inputId_], [OSCValue createWithFloat:(float)gain]);
	}
}

void FairlightAudioSourceMonitor::updatePan() const
{
	if (switcher.mFairlightAudioSources.count(inputId_) > 0)
	{
		double pan;
		switcher.mFairlightAudioSources[inputId_][sourceId_]->GetPan(&pan);
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/balance", inputId_], [OSCValue createWithFloat:(float)pan]);
		
		NSString *address = @"/audio/input/%lld/left/balance";
		if (sourceId_ == switcher.mFairlightAudioSources[inputId_].end()->first)
			address = @"/audio/input/%lld/right/balance";
		sendFeedbackMessage(switcher, [NSString stringWithFormat:address, inputId_], [OSCValue createWithFloat:(float)pan]);
	}
}

void FairlightAudioSourceMonitor::updateMixOption() const
{
	if (switcher.mFairlightAudioSources.count(inputId_) > 0)
	{
		BMDSwitcherFairlightAudioMixOption mix;
		switcher.mFairlightAudioSources[inputId_][sourceId_]->GetMixOption(&mix);
		
		NSString *mixOptionString = @"";
		if (mix == bmdSwitcherFairlightAudioMixOptionAudioFollowVideo)
			mixOptionString = @"afv";
		else if (mix == bmdSwitcherFairlightAudioMixOptionOn)
			mixOptionString = @"on";
		else if (mix == bmdSwitcherFairlightAudioMixOptionOff)
			mixOptionString = @"off";
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/audio/input/%lld/mix", inputId_], [OSCValue createWithString:mixOptionString]);
		
		NSString *address = @"/audio/input/%lld/left/mix";
		if (sourceId_ == switcher.mFairlightAudioSources[inputId_].end()->first)
			address = @"/audio/input/%lld/right/mix";
		sendFeedbackMessage(switcher, [NSString stringWithFormat:address, inputId_], [OSCValue createWithString:mixOptionString]);
	}
}

float FairlightAudioSourceMonitor::sendStatus() const
{
	updateFaderGain();
	updatePan();
	updateMixOption();

	return 0.03;
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
		sendFeedbackMessage(switcher, @"/audio/output/gain", [OSCValue createWithFloat:(float)gain]);
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
	updateSingleClipPlayback();
	updateLoopedPlayback();
	
	return 0.05;
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
		case bmdSwitcherHyperDeckEventTypeSingleClipPlaybackChanged:
			updateSingleClipPlayback();
			break;
		case bmdSwitcherHyperDeckEventTypeLoopedPlaybackChanged:
			updateLoopedPlayback();
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
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/clip", hyperdeckId_], [OSCValue createWithInt:(int)clipId+1]);
	}
}

void HyperDeckMonitor::updateCurrentClipTime() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		uint16_t hours;
		uint8_t minutes, seconds, frames;
		switcher.mHyperdecks[hyperdeckId_]->GetCurrentClipTime(&hours, &minutes, &seconds, &frames);
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/clip-time", hyperdeckId_], [OSCValue createWithString:[NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds]]);
	}
}

void HyperDeckMonitor::updateCurrentTimelineTime() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		uint16_t hours;
		uint8_t minutes, seconds, frames;
		switcher.mHyperdecks[hyperdeckId_]->GetCurrentTimelineTime(&hours, &minutes, &seconds, &frames);

		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/timeline-time", hyperdeckId_], [OSCValue createWithString:[NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds]]);
	}
}

void HyperDeckMonitor::updatePlayerState() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		BMDSwitcherHyperDeckPlayerState state;
		switcher.mHyperdecks[hyperdeckId_]->GetPlayerState(&state);
		OSCValue *val;
		switch (state)
		{
			case bmdSwitcherHyperDeckStateIdle: val = [OSCValue createWithString:@"idle"]; break;
			case bmdSwitcherHyperDeckStatePlay: val = [OSCValue createWithString:@"play"]; break;
			case bmdSwitcherHyperDeckStateRecord: val = [OSCValue createWithString:@"record"]; break;
			case bmdSwitcherHyperDeckStateShuttle: val = [OSCValue createWithString:@"shuttle"]; break;
			case bmdSwitcherHyperDeckStateUnknown: val = [OSCValue createWithString:@"unknown"]; break;
		}
		
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/state", hyperdeckId_], val);
	}
}

void HyperDeckMonitor::updateSingleClipPlayback() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		bool singleClipPlayback;
		switcher.mHyperdecks[hyperdeckId_]->GetSingleClipPlayback(&singleClipPlayback);
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/single-clip", hyperdeckId_], [OSCValue createWithBool:singleClipPlayback]);
	}
}

void HyperDeckMonitor::updateLoopedPlayback() const
{
	if (switcher.mHyperdecks.count(hyperdeckId_) > 0)
	{
		bool loopPlayback;
		switcher.mHyperdecks[hyperdeckId_]->GetLoopedPlayback(&loopPlayback);
		sendFeedbackMessage(switcher, [NSString stringWithFormat:@"/hyperdeck/%lld/loop", hyperdeckId_], [OSCValue createWithBool:loopPlayback]);
	}
}
