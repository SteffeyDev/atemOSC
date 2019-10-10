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


HRESULT MixEffectBlockMonitor::Notify(BMDSwitcherMixEffectBlockEventType eventType)
{
    return S_OK;
}

HRESULT MixEffectBlockMonitor::PropertyChanged(BMDSwitcherMixEffectBlockEventType eventType)
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
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetProgramInput(&programId);
	
	for (auto const& it : static_cast<AppDelegate *>(appDel).mInputs)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/program/%lld",it.first]];
		if (programId==it.first) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

void MixEffectBlockMonitor::updatePreviewButtonSelection() const
{
	BMDSwitcherInputId    previewId;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetPreviewInput(&previewId);
	
	for (auto const& it : static_cast<AppDelegate *>(appDel).mInputs)
	{
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/preview/%lld",it.first]];
		if (previewId==it.first) {[newMsg addFloat:1.0];} else {[newMsg addFloat:0.0];}
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

void MixEffectBlockMonitor::updateInTransitionState()
{
	bool inTransition;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetInTransition(&inTransition);
	
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
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetTransitionPosition(&position);
	
	// Record when transition passes halfway so we can flip orientation of slider handle at the end of transition
	mCurrentTransitionReachedHalfway_ = (position >= 0.50);
	
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;        // slider handle moving in opposite direction
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/transition/bar"];
	[newMsg addFloat:1.0-sliderPosition/100];
	[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
}

void MixEffectBlockMonitor::updatePreviewTransitionEnabled() const
{
	bool position;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetPreviewTransition(&position);
	
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/transition/preview"];
	[newMsg addFloat: position ? 1.0 : 0.0];
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
	
	updatePreviewTransitionEnabled();
	
	double position;
	static_cast<AppDelegate *>(appDel).mMixEffectBlock->GetTransitionPosition(&position);
	double sliderPosition = position * 100;
	if (mMoveSliderDownwards)
		sliderPosition = 100 - position * 100;
	OSCMessage *newMsg = [OSCMessage createWithAddress:@"/atem/transition/bar"];
	[newMsg addFloat:1.0-sliderPosition/100];
	[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];

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
	// Have to delay slightly, otherwise fetch gets old name
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		NSString *name;
		static_cast<AppDelegate *>(appDel).mInputs[inputId_]->GetLongName((CFStringRef*)&name);
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/input/%lld/long-name", inputId_]];
		[newMsg addString:name];
		[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	});
}

void InputMonitor::updateShortName() const
{
	// Have to delay slightly, otherwise fetch gets old name
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		NSString *name;
		static_cast<AppDelegate *>(appDel).mInputs[inputId_]->GetShortName((CFStringRef*)&name);
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/input/%lld/short-name", inputId_]];
		[newMsg addString:name];
		[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
	});
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
	for(auto& key : [(AppDelegate *)appDel dsk])
	{
		bool isTied;
		key->GetTie(&isTied);

		// Deprecated
		OSCMessage *oldMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/set-tie/%d",i]];
		[oldMsg addInt: isTied];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:oldMsg];

		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/%d/tie",i]];
		[newMsg addInt: isTied];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];

		i++;
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

		// Deprecated
		OSCMessage *oldMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/on-air/%d",i]];
		[oldMsg addInt: isOnAir];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:oldMsg];

		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/dsk/%d/on-air",i]];
		[newMsg addInt: isOnAir];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];

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
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		bool isOnAir;
		key->GetOnAir(&isOnAir);

		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/on-air",i]];
		[newMsg addInt: isOnAir];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];

		i++;
	}
}

void UpstreamKeyerMonitor::updateUSKInputFill() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		BMDSwitcherInputId inputId;
		key->GetInputFill(&inputId);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/source/fill",i++]];
		[newMsg addInt: static_cast<int>(inputId)];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}

void UpstreamKeyerMonitor::updateUSKInputCut() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		BMDSwitcherInputId inputId;
		key->GetInputCut(&inputId);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/source/cut",i++]];
		[newMsg addInt: static_cast<int>(inputId)];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
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
	for(auto& key : [(AppDelegate *)appDel keyers])
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
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/type",i]];
		[newMsg addString: typeStr];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
		
		// Support for legacy clients like TouchOSC
		OSCMessage *newMsg2 = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/type/%@",i++, typeStr]];
		[newMsg2 addFloat: 1.0];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg2];
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
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		
		double clip;
		lumaParams->GetClip(&clip);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/clip",i++]];
		[newMsg addFloat:clip];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaGainParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		
		double gain;
		lumaParams->GetGain(&gain);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/gain",i++]];
		[newMsg addFloat:gain];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaPreMultipliedParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		
		bool preMultiplied;
		lumaParams->GetPreMultiplied(&preMultiplied);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/pre-multiplied",i++]];
		[newMsg addBOOL:preMultiplied];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerLumaParametersMonitor::updateUSKLumaInverseParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyLumaParameters* lumaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyLumaParameters, (void**)&lumaParams);
		
		bool inverse;
		lumaParams->GetInverse(&inverse);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/luma/inverse",i++]];
		[newMsg addBOOL:inverse];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
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
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		
		double hue;
		chromaParams->GetHue(&hue);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/chroma/hue",i++]];
		[newMsg addFloat:hue];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaGainParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		
		double gain;
		chromaParams->GetGain(&gain);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/chroma/gain",i++]];
		[newMsg addFloat:gain];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaYSuppressParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		
		double ySuppress;
		chromaParams->GetYSuppress(&ySuppress);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/chroma/y-suppress",i++]];
		[newMsg addFloat:ySuppress];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaLiftParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		
		double lift;
		chromaParams->GetLift(&lift);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/chroma/lift",i++]];
		[newMsg addFloat:lift];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
	}
}
void UpstreamKeyerChromaParametersMonitor::updateUSKChromaNarrowParameter() const
{
	int i = 1;
	for(auto& key : [(AppDelegate *)appDel keyers])
	{
		IBMDSwitcherKeyChromaParameters* chromaParams;
		key->QueryInterface(IID_IBMDSwitcherKeyChromaParameters, (void**)&chromaParams);
		
		bool narrow;
		chromaParams->GetNarrow(&narrow);
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/chroma/narrow",i++]];
		[newMsg addBOOL:narrow];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
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
	uint32_t transitionSelections[5] = { bmdSwitcherTransitionSelectionBackground, bmdSwitcherTransitionSelectionKey1, bmdSwitcherTransitionSelectionKey2, bmdSwitcherTransitionSelectionKey3, bmdSwitcherTransitionSelectionKey4 };

	uint32_t currentTransitionSelection;
	static_cast<AppDelegate *>(appDel).switcherTransitionParameters->GetNextTransitionSelection(&currentTransitionSelection);

	for (int i = 0; i <= ((int) reinterpret_cast<AppDelegate *>(appDel).keyers.size()); i++) {
		uint32_t requestedTransitionSelection = transitionSelections[i];

		// Deprecated
		OSCMessage *oldMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/nextusk/%d",i]];
		[oldMsg addInt: ((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:oldMsg];
		
		OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/usk/%d/tie",i]];
		[newMsg addInt: ((requestedTransitionSelection & currentTransitionSelection) == requestedTransitionSelection)];
		[static_cast<AppDelegate *>(appDel).outPort sendThisMessage:newMsg];
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
	static_cast<AppDelegate *>(appDel).mAudioInputs[inputId_]->GetGain(&gain);
	OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/audio/input/%lld/gain", inputId_]];
	[newMsg addFloat:(float)gain];
	[[static_cast<AppDelegate *>(appDel) outPort] sendThisMessage:newMsg];
}

void AudioInputMonitor::updateBalance() const
{
	double balance;
	static_cast<AppDelegate *>(appDel).mAudioInputs[inputId_]->GetBalance(&balance);
	OSCMessage *newMsg = [OSCMessage createWithAddress:[NSString stringWithFormat:@"/atem/audio/input/%lld/balance", inputId_]];
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



