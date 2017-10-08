#include "FeedbackMonitors.h"
#import "AppDelegate.h"

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

HRESULT STDMETHODCALLTYPE SwitcherMonitor::Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode)
{
    if (eventType == bmdSwitcherEventTypeDisconnected)
    {
        [(AppDelegate *)appDel performSelectorOnMainThread:@selector(switcherDisconnected) withObject:nil waitUntilDone:YES];
    }
    return S_OK;
}



