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
	GenericMonitor(void *delegate) : appDel(delegate), mRefCount(1) { }
	HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv);
	ULONG STDMETHODCALLTYPE AddRef(void);
	ULONG STDMETHODCALLTYPE Release(void);
	
protected:
	virtual ~GenericMonitor() { }
	void *appDel;
	
private:
	int mRefCount;
};

// Callback class for monitoring property changes on a mix effect block.
class MixEffectBlockMonitor : public GenericMonitor<IBMDSwitcherMixEffectBlockCallback>
{
public:
	MixEffectBlockMonitor(void *delegate) : GenericMonitor(delegate) { }
	HRESULT PropertyChanged(BMDSwitcherMixEffectBlockPropertyId propertyId);
	bool moveSliderDownwards() const;
	bool mMoveSliderDownwards = false;
	void updateProgramButtonSelection() const;
	void updatePreviewButtonSelection() const;
	void updateInTransitionState();
	void updateSliderPosition();
	void sendStatus() const;
	
protected:
	virtual ~MixEffectBlockMonitor() { }
	
private:
	bool mCurrentTransitionReachedHalfway_ = false;
};

class DownstreamKeyerMonitor : public GenericMonitor<IBMDSwitcherDownstreamKeyCallback>
{
public:
	DownstreamKeyerMonitor(void *delegate) : GenericMonitor(delegate) { }
	HRESULT Notify (BMDSwitcherDownstreamKeyEventType eventType);
	void sendStatus() const;
	
protected:
	virtual ~DownstreamKeyerMonitor() { }
	
private:
	void updateDSKOnAir() const;
	void updateDSKTie() const;
};

class TransitionParametersMonitor : public GenericMonitor<IBMDSwitcherTransitionParametersCallback>
{
public:
	TransitionParametersMonitor(void *delegate) : GenericMonitor(delegate) { }
	HRESULT Notify (BMDSwitcherTransitionParametersEventType eventType);
	void sendStatus() const;
	
protected:
	virtual ~TransitionParametersMonitor() { }
	
private:
	void updateTransitionParameters() const;
};

class MacroPoolMonitor : public GenericMonitor<IBMDSwitcherMacroPoolCallback>
{
public:
	MacroPoolMonitor(void *delegate) : GenericMonitor(delegate) { }
	HRESULT Notify (BMDSwitcherMacroPoolEventType eventType, uint32_t index, IBMDSwitcherTransferMacro* macroTransfer);
	void sendStatus() const;
	
protected:
	virtual ~MacroPoolMonitor() { }
	
private:
	void updateMacroName(int index) const;
	void updateMacroDescription(int index) const;
	void updateNumberOfMacros() const;
	void updateMacroValidity(int index) const;
};

// Callback class to monitor switcher disconnection
class SwitcherMonitor : public GenericMonitor<IBMDSwitcherCallback>
{
public:
	SwitcherMonitor(void *delegate) : GenericMonitor(delegate) { }
	HRESULT STDMETHODCALLTYPE Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode);
	void sendStatus() const;
	
protected:
	virtual ~SwitcherMonitor() { }
};

#endif /* SwitcherMonitor_h */
