#import "BMDSwitcherAPI.h"
#import "VVOSC/VVOSC.h"
#import <list>
#import <vector>

@class Switcher;

#ifndef SwitcherMonitor_h
#define SwitcherMonitor_h

// sendStatus should return the delay, or how long we think we
// should wait after those send commands to allow time for the
// network queue to flush, to make sure we don't flood the network
// too fast.  Monitors that only send 1-2 commands should only delay
// less than 0.05 seconds, while monitors that sends 10-20 commands
// may need to delay 0.1 - 0.3 seconds
class SendStatusInterface
{
public:
	virtual float sendStatus() const = 0;
};

template <class T=IUnknown>
class GenericMonitor : public T
{
public:
	GenericMonitor(Switcher *_switcher) : switcher(_switcher), mRefCount(1) { }
	HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv);
	ULONG STDMETHODCALLTYPE AddRef(void);
	ULONG STDMETHODCALLTYPE Release(void);
	
protected:
	virtual ~GenericMonitor() { }
	Switcher *switcher;
	
private:
	int mRefCount;
};

// Callback class for monitoring property changes on a mix effect block.
class MixEffectBlockMonitor : public GenericMonitor<IBMDSwitcherMixEffectBlockCallback>, public SendStatusInterface
{
public:
	MixEffectBlockMonitor(Switcher *switcher, int me) : GenericMonitor(switcher), me_(me) { }
	HRESULT Notify(BMDSwitcherMixEffectBlockEventType eventType);
	bool moveSliderDownwards() const;
	bool mMoveSliderDownwards = false;
	void updateSliderPosition();
	void updatePreviewTransitionEnabled() const;
	float sendStatus() const;
	
protected:
	virtual ~MixEffectBlockMonitor() { }
	
private:
	void updateProgramButtonSelection() const;
	void updatePreviewButtonSelection() const;
	void updateInTransitionState();
	bool mCurrentTransitionReachedHalfway_ = false;
	int me_;
};

class InputMonitor : public GenericMonitor<IBMDSwitcherInputCallback>, public SendStatusInterface
{
public:
	InputMonitor(Switcher *switcher, BMDSwitcherInputId inputId) : GenericMonitor(switcher), inputId_(inputId) { }
	HRESULT Notify(BMDSwitcherInputEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~InputMonitor() { }
	
private:
	void updateShortName() const;
	void updateLongName() const;
	BMDSwitcherInputId  inputId_;
};

class InputAuxMonitor : public GenericMonitor<IBMDSwitcherInputAuxCallback>, public SendStatusInterface
{
public:
	InputAuxMonitor(Switcher *switcher, BMDSwitcherInputId inputId) : GenericMonitor(switcher), inputId_(inputId) { }
	HRESULT Notify(BMDSwitcherInputAuxEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~InputAuxMonitor() { }
	
private:
	void updateInputSource() const;
	BMDSwitcherInputId  inputId_;
};

class DownstreamKeyerMonitor : public GenericMonitor<IBMDSwitcherDownstreamKeyCallback>, public SendStatusInterface
{
public:
	DownstreamKeyerMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT Notify (BMDSwitcherDownstreamKeyEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~DownstreamKeyerMonitor() { }
	
private:
	void updateDSKOnAir() const;
	void updateDSKTie() const;
};

class UpstreamKeyerMonitor : public GenericMonitor<IBMDSwitcherKeyCallback>, public SendStatusInterface
{
public:
	UpstreamKeyerMonitor(Switcher *switcher, int me) : GenericMonitor(switcher), me_(me) { }
	HRESULT Notify (BMDSwitcherKeyEventType eventType);
	float sendStatus() const;

protected:
	virtual ~UpstreamKeyerMonitor() { }

private:
	void updateUSKOnAir() const;
	void updateUSKInputFill() const;
	void updateUSKInputCut() const;
	void updateUSKType() const;
	int me_;
};

class UpstreamKeyerLumaParametersMonitor : public GenericMonitor<IBMDSwitcherKeyLumaParametersCallback>, public SendStatusInterface
{
public:
	UpstreamKeyerLumaParametersMonitor(Switcher *switcher, int me) : GenericMonitor(switcher), me_(me) { }
	HRESULT Notify (BMDSwitcherKeyLumaParametersEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~UpstreamKeyerLumaParametersMonitor() { }
	
private:
	void updateUSKLumaClipParameter() const;
	void updateUSKLumaGainParameter() const;
	void updateUSKLumaPreMultipliedParameter() const;
	void updateUSKLumaInverseParameter() const;
	int me_;
};

class UpstreamKeyerChromaParametersMonitor : public GenericMonitor<IBMDSwitcherKeyChromaParametersCallback>, public SendStatusInterface
{
public:
	UpstreamKeyerChromaParametersMonitor(Switcher *switcher, int me) : GenericMonitor(switcher), me_(me) { }
	HRESULT Notify (BMDSwitcherKeyChromaParametersEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~UpstreamKeyerChromaParametersMonitor() { }
	
private:
	void updateUSKChromaHueParameter() const;
	void updateUSKChromaGainParameter() const;
	void updateUSKChromaYSuppressParameter() const;
	void updateUSKChromaLiftParameter() const;
	void updateUSKChromaNarrowParameter() const;
	int me_;
};

class TransitionParametersMonitor : public GenericMonitor<IBMDSwitcherTransitionParametersCallback>, public SendStatusInterface
{
public:
	TransitionParametersMonitor(Switcher *switcher, int me) : GenericMonitor(switcher), me_(me) { }
	HRESULT Notify (BMDSwitcherTransitionParametersEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~TransitionParametersMonitor() { }
	
private:
	void updateTransitionParameters() const;
	int me_;
};

class MacroPoolMonitor : public GenericMonitor<IBMDSwitcherMacroPoolCallback>, public SendStatusInterface
{
public:
	MacroPoolMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT Notify (BMDSwitcherMacroPoolEventType eventType, uint32_t index, IBMDSwitcherTransferMacro* macroTransfer);
	float sendStatus() const;
	
protected:
	virtual ~MacroPoolMonitor() { }
	
private:
	void updateMacroName(int index) const;
	void updateMacroDescription(int index) const;
	void updateNumberOfMacros() const;
	void updateMacroValidity(int index) const;
};

class MacroControlMonitor : public GenericMonitor<IBMDSwitcherMacroControlCallback>, public SendStatusInterface
{
public:
	MacroControlMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT Notify (BMDSwitcherMacroControlEventType eventType);
	float sendStatus() const;
	
protected:
	virtual ~MacroControlMonitor() { }
	
private:
	void updateRunStatus() const;
};

// Callback class to monitor switcher disconnection
class SwitcherMonitor : public GenericMonitor<IBMDSwitcherCallback>, public SendStatusInterface
{
public:
	SwitcherMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT STDMETHODCALLTYPE Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode);
	float sendStatus() const;
	
protected:
	virtual ~SwitcherMonitor() { }
};

// Callback class to monitor audio inputs
class AudioInputMonitor : public GenericMonitor<IBMDSwitcherAudioInputCallback>, public SendStatusInterface
{
public:
	AudioInputMonitor(Switcher *switcher, BMDSwitcherAudioInputId inputId) : GenericMonitor(switcher), inputId_(inputId) { }
	HRESULT STDMETHODCALLTYPE Notify (BMDSwitcherAudioInputEventType eventType);
	HRESULT STDMETHODCALLTYPE LevelNotification (double left, double right, double peakLeft, double peakRight);
	float sendStatus() const;
	
protected:
	virtual ~AudioInputMonitor() { }
	
private:
	void updateGain() const;
	void updateBalance() const;
	void updateMixOption() const;
	BMDSwitcherAudioInputId  inputId_;
};

// Callback class to monitor audio mixer
class AudioMixerMonitor : public GenericMonitor<IBMDSwitcherAudioMixerCallback>, public SendStatusInterface
{
public:
	AudioMixerMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT STDMETHODCALLTYPE Notify (BMDSwitcherAudioMixerEventType eventType);
	HRESULT STDMETHODCALLTYPE ProgramOutLevelNotification (double left, double right, double peakLeft, double peakRight);
	float sendStatus() const;
	
protected:
	virtual ~AudioMixerMonitor() { }
	
private:
	void updateGain() const;
	void updateBalance() const;
};

// Callback class to monitor fairlight audio sources
class FairlightAudioSourceMonitor : public GenericMonitor<IBMDSwitcherFairlightAudioSourceCallback>, public SendStatusInterface
{
public:
	FairlightAudioSourceMonitor(Switcher *switcher, BMDSwitcherFairlightAudioSourceId sourceId, BMDSwitcherAudioInputId inputId) : GenericMonitor(switcher), sourceId_(sourceId), inputId_(inputId) { }
	HRESULT STDMETHODCALLTYPE Notify (BMDSwitcherFairlightAudioSourceEventType eventType);
	HRESULT STDMETHODCALLTYPE OutputLevelNotification (uint32_t numLevels, const double* levels, uint32_t numPeakLevels, const double* peakLevels);
	float sendStatus() const;
	
protected:
	virtual ~FairlightAudioSourceMonitor() { }
	
private:
	void updateFaderGain() const;
	void updatePan() const;
	void updateMixOption() const;
	BMDSwitcherAudioInputId  inputId_;
	BMDSwitcherFairlightAudioSourceId  sourceId_;
};

// Callback class to monitor fairlight audio inputs
class FairlightAudioInputMonitor : public GenericMonitor<IBMDSwitcherFairlightAudioInputCallback>, public SendStatusInterface
{
public:
	FairlightAudioInputMonitor(Switcher *switcher, BMDSwitcherAudioInputId inputId) : GenericMonitor(switcher), inputId_(inputId) { }
	HRESULT STDMETHODCALLTYPE Notify (BMDSwitcherFairlightAudioInputEventType eventType);
	float sendStatus() const { return 0.0; };
	
protected:
	virtual ~FairlightAudioInputMonitor() { }
	
private:
	BMDSwitcherAudioInputId  inputId_;
};

// Callback class to monitor fairlight audio mixer
class FairlightAudioMixerMonitor : public GenericMonitor<IBMDSwitcherFairlightAudioMixerCallback>, public SendStatusInterface
{
public:
	FairlightAudioMixerMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT STDMETHODCALLTYPE Notify (BMDSwitcherFairlightAudioMixerEventType eventType);
    HRESULT STDMETHODCALLTYPE MasterOutLevelNotification (uint32_t numLevels, const double* levels, uint32_t numPeakLevels, const double* peakLevels);

	float sendStatus() const;
	
protected:
	virtual ~FairlightAudioMixerMonitor() { }
	
private:
	void updateGain() const;
};

// Callback class to monitor HyperDecks
class HyperDeckMonitor : public GenericMonitor<IBMDSwitcherHyperDeckCallback>, public SendStatusInterface
{
public:
	HyperDeckMonitor(Switcher *switcher, BMDSwitcherHyperDeckId hyperdeckId) : GenericMonitor(switcher), hyperdeckId_(hyperdeckId) { }
	HRESULT Notify(BMDSwitcherHyperDeckEventType eventType);
	HRESULT NotifyError(BMDSwitcherHyperDeckErrorType eventType) { return S_OK; }
	float sendStatus() const;
	
protected:
	virtual ~HyperDeckMonitor() { }
	
private:
	void updateCurrentClip() const;
	void updateCurrentClipTime() const;
	void updateCurrentTimelineTime() const;
	void updatePlayerState() const;
	void updateSingleClipPlayback() const;
	void updateLoopedPlayback() const;
	BMDSwitcherHyperDeckId  hyperdeckId_;
};

class RecordAVMonitor : public GenericMonitor<IBMDSwitcherRecordAVCallback>, public SendStatusInterface
{
public:
	RecordAVMonitor(Switcher *switcher) : GenericMonitor(switcher) { }
	HRESULT NotifyStatus(BMDSwitcherRecordAVState stateType, BMDSwitcherRecordAVError error);
	// Ignore these three, don't want to use them yet
	HRESULT Notify(BMDSwitcherRecordAVEventType eventTye) { return S_OK; };
	HRESULT NotifyWorkingSetChange(uint32_t workingSetIndex, BMDSwitcherRecordDiskId diskId) { return S_OK; };
	HRESULT NotifyDiskAvailability(BMDSwitcherRecordDiskAvailabilityEventType eventType, BMDSwitcherRecordDiskId diskId) { return S_OK; };
	float sendStatus() const;
	
protected:
	virtual ~RecordAVMonitor() { }
	
private:
	void updateState(BMDSwitcherRecordAVState stateType, BMDSwitcherRecordAVError error) const;
};

#endif /* SwitcherMonitor_h */
