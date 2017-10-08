//
//  SwitcherMonitor.h
//  atemOSC
//
//  Created by Peter Steffey on 10/2/17.
//

#import "BMDSwitcherAPI.h"
#import "VVOSC/VVOSC.h"
#import <list>
#import <vector>

#ifndef SwitcherMonitor_h
#define SwitcherMonitor_h

template <class T=IUnknown>
class GenericMonitor : public T
{
public:
    GenericMonitor(OSCOutPort *outPort) : outPort_(outPort), mRefCount(1) { }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv);
    ULONG STDMETHODCALLTYPE AddRef(void);
    ULONG STDMETHODCALLTYPE Release(void);
    
protected:
    virtual ~GenericMonitor() { }
    OSCOutPort *outPort_;
    
private:
    int mRefCount;
    
};

// Callback class for monitoring property changes on a mix effect block.
class MixEffectBlockMonitor : public GenericMonitor<IBMDSwitcherMixEffectBlockCallback>
{
public:
    MixEffectBlockMonitor(OSCOutPort *outPort, IBMDSwitcherMixEffectBlock* mixEffectBlock) : mMixEffectBlock_(mixEffectBlock), GenericMonitor(outPort) { }
    HRESULT PropertyChanged(BMDSwitcherMixEffectBlockPropertyId propertyId);
    bool moveSliderDownwards() const;
    bool mMoveSliderDownwards = false;
    void updateProgramButtonSelection() const;
    void updatePreviewButtonSelection() const;
    void updateInTransitionState();
    void updateSliderPosition();
    
protected:
    virtual ~MixEffectBlockMonitor() { }

private:
    IBMDSwitcherMixEffectBlock* mMixEffectBlock_;
    bool                        mCurrentTransitionReachedHalfway_ = false;
};

class DownstreamKeyerMonitor : public GenericMonitor<IBMDSwitcherDownstreamKeyCallback>
{
public:
    DownstreamKeyerMonitor(OSCOutPort *outPort, std::list<IBMDSwitcherDownstreamKey*> dsk);
    HRESULT Notify (BMDSwitcherDownstreamKeyEventType eventType);
    
protected:
    virtual ~DownstreamKeyerMonitor() { }
    
private:
    void updateDSKOnAir() const;
    void updateDSKTie() const;
    std::list<IBMDSwitcherDownstreamKey*> dsk_;
};

class TransitionParametersMonitor : public GenericMonitor<IBMDSwitcherTransitionParametersCallback>
{
public:
    TransitionParametersMonitor(OSCOutPort *outPort, IBMDSwitcherTransitionParameters* switcherTransitionParameters, std::list<IBMDSwitcherKey*> keyers) : switcherTransitionParameters_(switcherTransitionParameters), keyers_(keyers), GenericMonitor(outPort) { }
    HRESULT Notify (BMDSwitcherTransitionParametersEventType eventType);
    
protected:
    virtual ~TransitionParametersMonitor() { }
    
private:
    void updateTransitionParameters() const;
    IBMDSwitcherTransitionParameters*   switcherTransitionParameters_;
    std::list<IBMDSwitcherKey*>         keyers_;
};

// Monitor the properties on Switcher Inputs.
// In this sample app we're only interested in changes to the Long Name property to update the PopupButton list
class InputMonitor : public GenericMonitor<IBMDSwitcherInputCallback>
{
public:
    InputMonitor(IBMDSwitcherInput* input, OSCOutPort *outPort, void *mUiDelegate);
    HRESULT Notify(BMDSwitcherInputEventType eventType);
    IBMDSwitcherInput* input();
    
protected:
    ~InputMonitor();
    
private:
    IBMDSwitcherInput*  mInput;
    void* mUiDelegate_;
};

// Callback class to monitor switcher disconnection
class SwitcherMonitor : public GenericMonitor<IBMDSwitcherCallback>
{
public:
    SwitcherMonitor(OSCOutPort *outPort, void *mUiDelegate);
    HRESULT STDMETHODCALLTYPE Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode);
    
protected:
    virtual ~SwitcherMonitor() { }
    
private:
    void* mUiDelegate_;
};

#endif /* SwitcherMonitor_h */
