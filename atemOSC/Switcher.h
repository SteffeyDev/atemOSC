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

NS_ASSUME_NONNULL_BEGIN

@interface Switcher : NSObject<NSCoding>
{
	std::map<BMDSwitcherInputId, InputMonitor*> mInputMonitors;
	SwitcherMonitor*			        mSwitcherMonitor;
	std::map<BMDSwitcherHyperDeckId, HyperDeckMonitor*> mHyperdeckMonitors;
	DownstreamKeyerMonitor*             mDownstreamKeyerMonitor;
	UpstreamKeyerMonitor*               mUpstreamKeyerMonitor;
	UpstreamKeyerLumaParametersMonitor* mUpstreamKeyerLumaParametersMonitor;
	UpstreamKeyerChromaParametersMonitor* mUpstreamKeyerChromaParametersMonitor;
	TransitionParametersMonitor*        mTransitionParametersMonitor;
	MacroPoolMonitor*       			mMacroPoolMonitor;
	AudioMixerMonitor*                  mAudioMixerMonitor;
	std::map<BMDSwitcherAudioInputId, AudioInputMonitor*> mAudioInputMonitors;
	std::map<BMDSwitcherFairlightAudioSourceId, FairlightAudioSourceMonitor*> mFairlightAudioSourceMonitors;
	FairlightAudioMixerMonitor*         mFairlightAudioMixerMonitor;

	std::vector<SendStatusInterface*>   mMonitors;
}

@property(nonatomic, retain) NSString *ipAddress;
@property(nonatomic, retain) NSString *feedbackIpAddress;
@property(nonatomic) int feedbackPort;
@property(nonatomic, retain) NSString *nickname;
@property(nonatomic) BOOL connectAutomatically;

@property(nonatomic, assign) NSString *productName;


@property (nonatomic)       bool                                     isConnected;
@property (nonatomic)       bool                                     connecting;


@property (assign, readonly) OSCOutPort*                    outPort;

@property (readonly)       IBMDSwitcher*				        	mSwitcher;
@property (readonly)       std::vector<IBMDSwitcherSuperSourceBox*> mSuperSourceBoxes;
@property (readonly)       std::map<BMDSwitcherInputId, IBMDSwitcherInput*> mInputs;
@property (readonly)       std::map<BMDSwitcherHyperDeckId, IBMDSwitcherHyperDeck*> mHyperdecks;
@property (readonly)       std::vector<IBMDSwitcherInputAux*>       mSwitcherInputAuxList;
@property (readonly)       IBMDSwitcherInputSuperSource*            mSuperSource;
@property (readonly)       IBMDSwitcherMacroPool*                   mMacroPool;
@property (readonly)       IBMDSwitcherMacroControl*                mMacroControl;
@property (readonly)       std::vector<IBMDSwitcherMediaPlayer*>    mMediaPlayers;
@property (readonly)       IBMDSwitcherMediaPool*                   mMediaPool;
@property (readonly)       std::vector<IBMDSwitcherKey*>            keyers;
@property (readonly)       std::vector<IBMDSwitcherDownstreamKey*>  dsk;
@property (readonly)       IBMDSwitcherKeyFlyParameters*	    	mDVEControl;
@property (readonly)       IBMDSwitcherTransitionParameters*        switcherTransitionParameters;
@property (readonly)       MixEffectBlockMonitor*                   mMixEffectBlockMonitor;
@property (readonly)       IBMDSwitcherMixEffectBlock*              mMixEffectBlock;

@property (readonly)       std::map<BMDSwitcherAudioInputId, IBMDSwitcherAudioInput*> mAudioInputs;
@property (readonly)       IBMDSwitcherAudioMixer*                  mAudioMixer;

@property (readonly)       std::map<BMDSwitcherFairlightAudioSourceId, IBMDSwitcherFairlightAudioSource*> mFairlightAudioSources;
@property (readonly)       IBMDSwitcherFairlightAudioMixer*         mFairlightAudioMixer;

- (void)connectBMD;
- (void)switcherConnected;
- (void)switcherDisconnected;
- (void)cleanUpConnection;

- (void)sendStatus;
- (void)sendEachStatus:(int)nextMonitor;

- (void)saveChanges;
- (void)updateFeedback;

@end

NS_ASSUME_NONNULL_END
