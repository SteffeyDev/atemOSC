//
//  Switcher.h
//  AtemOSC
//
//  Created by Peter Steffey on 12/26/20.
//

#import <Foundation/Foundation.h>
#import "BMDSwitcherAPI.h"
#import "VVOSC/VVOSC.h"
#import "FeedbackMonitors.h"
#import <vector>
#import <map>
#import <list>
@class AppDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface Switcher : NSObject<NSCoding>
{
	std::map<BMDSwitcherInputId, InputMonitor*>			mInputMonitors;
	std::map<BMDSwitcherInputId, InputAuxMonitor*>			mAuxInputMonitors;
	SwitcherMonitor*			        				mSwitcherMonitor;
	std::map<BMDSwitcherHyperDeckId, HyperDeckMonitor*> mHyperdeckMonitors;
	DownstreamKeyerMonitor*             				mDownstreamKeyerMonitor;
	std::map<int, UpstreamKeyerMonitor*>				mUpstreamKeyerMonitors;
	std::map<int, UpstreamKeyerLumaParametersMonitor*>	mUpstreamKeyerLumaParametersMonitors;
	std::map<int, UpstreamKeyerChromaParametersMonitor*> mUpstreamKeyerChromaParametersMonitors;
	std::map<int, UpstreamKeyerFlyParametersMonitor*> mUpstreamKeyerFlyParametersMonitors;
	std::map<int, UpstreamKeyerPatternParametersMonitor*> mUpstreamKeyerPatternParametersMonitors;
	std::map<int, TransitionParametersMonitor*>			mTransitionParametersMonitors;
	MacroPoolMonitor*       							mMacroPoolMonitor;
	MacroControlMonitor*       							mMacroControlMonitor;
	AudioMixerMonitor*                  				mAudioMixerMonitor;
	std::map<BMDSwitcherAudioInputId, AudioInputMonitor*> mAudioInputMonitors;
	std::map<BMDSwitcherAudioInputId, FairlightAudioInputMonitor*> mFairlightAudioInputMonitors;
	std::map<BMDSwitcherAudioInputId, std::map<BMDSwitcherFairlightAudioSourceId, FairlightAudioSourceMonitor*> > mFairlightAudioSourceMonitors;
	RecordAVMonitor*       								mRecordAVMonitor;
	StreamMonitor*       								mStreamMonitor;
	FairlightAudioMixerMonitor*         				mFairlightAudioMixerMonitor;

	std::vector<SendStatusInterface*>   mMonitors;
	
	AppDelegate *appDel;
}

@property(nonatomic, retain) NSString *uid;

@property(nonatomic, retain) NSString *ipAddress;
@property(nonatomic, retain) NSString *feedbackIpAddress;
@property(nonatomic) int feedbackPort;
@property(nonatomic, retain) NSString *nickname;
@property(nonatomic) BOOL connectAutomatically;

@property(nonatomic, assign) NSString *productName;


@property (nonatomic)         bool     isConnected;
@property (nonatomic, assign) NSString *connectionStatus;

@property (nonatomic)         bool     inverseHandle;

@property (assign, readonly) OSCOutPort*                    outPort;

@property (readonly)       IBMDSwitcher*				        	mSwitcher;
@property (readonly)       std::vector<IBMDSwitcherMixEffectBlock*> mMixEffectBlocks;
@property (readonly)	   std::map<int, MixEffectBlockMonitor *>	mMixEffectBlockMonitors;
@property (readonly)       std::map<int, std::vector<IBMDSwitcherKey*> > keyers;
@property (readonly)       std::vector<IBMDSwitcherSuperSourceBox*> mSuperSourceBoxes;
@property (readonly)       std::map<BMDSwitcherInputId, IBMDSwitcherInput*> mInputs;
@property (readonly)       std::map<BMDSwitcherInputId, IBMDSwitcherInputAux*> mAuxInputs;
@property (readonly)       std::map<BMDSwitcherHyperDeckId, IBMDSwitcherHyperDeck*> mHyperdecks;
@property (readonly)       IBMDSwitcherInputSuperSource*            mSuperSource;
@property (readonly)       IBMDSwitcherMacroPool*                   mMacroPool;
@property (readonly)       IBMDSwitcherMacroControl*                mMacroControl;
@property (readonly)       std::vector<IBMDSwitcherMediaPlayer*>    mMediaPlayers;
@property (readonly)       IBMDSwitcherMediaPool*                   mMediaPool;
@property (readonly)       std::vector<IBMDSwitcherDownstreamKey*>  dsk;
@property (readonly)       IBMDSwitcherRecordAV*	    			mRecordAV;
@property (readonly)       IBMDSwitcherStreamRTMP*					mStreamRTMP;

@property (readonly)       std::map<BMDSwitcherAudioInputId, IBMDSwitcherAudioInput*> mAudioInputs;
@property (readonly)       IBMDSwitcherAudioMixer*                  mAudioMixer;

@property (readonly)       std::map<BMDSwitcherAudioInputId, IBMDSwitcherFairlightAudioInput*> mFairlightAudioInputs;
@property (readonly)       std::map<BMDSwitcherAudioInputId, std::map<BMDSwitcherFairlightAudioSourceId, IBMDSwitcherFairlightAudioSource*> > mFairlightAudioSources;
@property (readonly)       IBMDSwitcherFairlightAudioMixer*         mFairlightAudioMixer;

- (void)setAppDelegate:(AppDelegate *)appDel;

- (void)connectBMD;
- (void)disconnectBMD;
- (void)switcherConnected;
- (void)switcherDisconnected:(BOOL)reconnect;
- (void)cleanUpConnection;

- (void)sendStatus;
- (void)sendEachStatus:(int)nextMonitor;

- (void)saveChanges;
- (void)updateFeedback;

- (void)loadFairlightAudio;

- (void)logMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
