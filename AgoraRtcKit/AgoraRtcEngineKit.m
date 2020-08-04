//
//  AgoraRtcEngineKit.m
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/15.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import "AgoraRtcEngineKit.h"
//#import "thunderbolt/ThunderEngine.h"
#import "ThunderEngine.h"
#import "TransformHelper.h"
#import "CustomVideoSource.h"

// workaround for setLocalVoiceEqualizationOfBandFrequency
ThunderEqGainsOc gains;

@interface AgoraRtcEngineKit() <ThunderEventDelegate, ThunderVideoDecodeFrameObserver, ThunderAudioFilePlayerDelegate>
@property(nonatomic, strong) ThunderEngine* thunderEngine;

//
@property(nonatomic, strong) NSMutableArray* remoteUidArray;

// workaround for publish CDN with transcoding
@property(nonatomic, strong) NSMutableSet* transcodingUrls;

// workaround for switch camera
@property(nonatomic, assign) BOOL isFrontCamera;

// workaround for user account
@property(nonatomic, copy) NSString* localAccount;
@property(nonatomic, assign) NSInteger localIntUid;

// workaround for set video source
@property(nonatomic, strong) CustomVideoSource* thunderVideoSource;
@property(nonatomic, strong) CustomExternalVideoSource* thunderExternalVideoSource;

// workaround for audio mix
@property(nonatomic, strong) ThunderAudioFilePlayer* audioMixer;

// workaround for audio effect
@property(nonatomic, strong) NSMutableDictionary* audioEffectPlayers;
@property(assign, nonatomic) double allEffectsVolume;
@property(nonatomic, strong) NSMutableSet* shouldPlayEffectPlayers;

// workaround for joinSuccess and leaveChannel block
@property(nonatomic, nullable, copy) void(^joinRoomSuccessBlock)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed);
@property(nonatomic, nullable, copy) void(^leaveChannelBlock)(AgoraChannelStats * _Nonnull stat);

// workaround for LiveBroadcasting client role
@property(nonatomic, assign) AgoraChannelProfile agoraChannelProfile;
@property(nonatomic, assign) AgoraClientRole agoraClientRole;
@property(nonatomic, assign) BOOL videoEnabled;
@property(nonatomic, assign) BOOL audioEnabled;
@property(nonatomic, assign) BOOL localVideoEnabled;
@property(nonatomic, assign) BOOL localAudioEnabled;
@property(nonatomic, assign) BOOL remoteVideoEnabled;
@property(nonatomic, assign) BOOL remoteAuidoEnabled;
@property(nonatomic, assign) BOOL roomJoined;

// workaround for firstRemoteVideoDecoded
@property(nonatomic, strong) NSMutableSet* videoDecodedSet;

// workaround for AgoraChannelStats
@property(nonatomic, strong) RoomStats* thunderRoomStats;
@property(nonatomic, strong) ThunderRtcLocalDeviceStats* deviceStats;

// workaround for setLocalVoiceReverbOfType
@property(nonatomic, assign) ThunderReverbExParamOc reverbParam;

@end

@implementation AgoraRtcEngineKit

static dispatch_once_t onceToken;
static id instance;

+ (instancetype _Nonnull)sharedEngineWithAppId:(NSString * _Nonnull)appId
                                      delegate:(id<AgoraRtcEngineDelegate> _Nullable)delegate {
    static AgoraRtcEngineKit* engine;
    dispatch_once(&onceToken, ^{
        engine = [[AgoraRtcEngineKit alloc] initWithAppId:appId delegate:delegate];
        engine.isFrontCamera = true;
        instance = engine;
    });
    engine.delegate = delegate;
    
    return engine;
}

+ (instancetype _Nonnull)sharedEngineWithConfig:(AgoraRtcEngineConfig * _Nonnull)config
                                       delegate:(id<AgoraRtcEngineDelegate> _Nullable)delegate {
    // config.areCode
    AgoraRtcEngineKit* engine = [AgoraRtcEngineKit sharedEngineWithAppId:config.appId delegate:delegate];
    return engine;
}

+ (void)destroy {
    [ThunderEngine destroyEngine];
    onceToken = 0;
    instance = nil;
}

- (void)clearStatus {
    for (int i = 0; i < 11; i++) {
        gains[i] = 0.0;
    }
    
    for (ThunderAudioFilePlayer* player in _audioEffectPlayers) {
        [_thunderEngine destroyAudioFilePlayer:player];
    }
    [_thunderEngine destroyAudioFilePlayer:_audioMixer];
    
    if (!_isFrontCamera) {
        [self switchCamera];
    }
    
    ThunderReverbExParamOc newParam = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,};
    _reverbParam = newParam;
    
    _videoDecodedSet = NULL;
    _transcodingUrls = NULL;
    _remoteUidArray = NULL;
    _audioEffectPlayers = NULL;
    
    _videoEnabled = false;
    _audioEnabled = false;
    _roomJoined = false;
}

- (instancetype)initWithAppId:(NSString * _Nonnull)appId
                     delegate:(id<AgoraRtcEngineDelegate> _Nullable)delegate {
    if (self = [super init]) {
        _thunderEngine = [ThunderEngine createEngine:appId sceneId:0 delegate:self];
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark lazy load
- (NSMutableArray*)remoteUidArray {
    if (!_remoteUidArray) {
        _remoteUidArray = [[NSMutableArray alloc] init];
    }
    return _remoteUidArray;;
}

- (ThunderAudioFilePlayer*)audioMixer {
    if (!_audioMixer) {
        _audioMixer = [_thunderEngine createAudioFilePlayer];
        [_audioMixer setPlayerDelegate:self];
    }
    return _audioMixer;
}

- (NSMutableDictionary*)audioEffectPlayers {
    if (!_audioEffectPlayers) {
        _audioEffectPlayers = [[NSMutableDictionary alloc] init];
    }
    return _audioEffectPlayers;
}

- (NSMutableSet*)shouldPlayEffectPlayers {
    if (!_shouldPlayEffectPlayers) {
        _shouldPlayEffectPlayers = [[NSMutableSet alloc] init];
    }
    return _shouldPlayEffectPlayers;
}

- (NSMutableSet*)transcodingUrls {
    if (!_transcodingUrls) {
        _transcodingUrls = [[NSMutableSet alloc] init];
    }
    return _transcodingUrls;
}

- (NSMutableSet*)videoDecodedSet {
    if (!_videoDecodedSet) {
        _videoDecodedSet = [[NSMutableSet alloc] init];
    }
    return _videoDecodedSet;
}

- (void)setAgoraClientRole:(AgoraClientRole)agoraClientRole {
    _agoraClientRole = agoraClientRole;
    if (_agoraChannelProfile != AgoraChannelProfileLiveBroadcasting) {
        return;
    }
    
    if (_roomJoined) {
        switch (agoraClientRole) {
            case AgoraClientRoleAudience: {
                [_thunderEngine stopLocalVideoStream:true];
                [_thunderEngine stopLocalAudioStream:true];
            }
                break;
            case AgoraClientRoleBroadcaster: {
                [_thunderEngine stopLocalVideoStream:!_videoEnabled];
                [_thunderEngine stopLocalAudioStream:!_audioEnabled];
            }
                break;
        }
    }
}

- (void)setRoomJoined:(BOOL)roomJoined {
    _roomJoined = roomJoined;
    if (!_roomJoined) { return; }
    if (_agoraChannelProfile == AgoraChannelProfileLiveBroadcasting && _agoraClientRole == AgoraClientRoleAudience) {
        [_thunderEngine stopAllRemoteAudioStreams:false];
        [_thunderEngine stopAllRemoteVideoStreams:false];
    } else {
        [self thunderEnableVideo:_videoEnabled];
        [self thunderEnableAudio:_audioEnabled];
    }
}

- (int)setChannelProfile:(AgoraChannelProfile)profile {
    _agoraChannelProfile = profile;
    return [_thunderEngine setRoomMode:[TransformHelper transformAgoraChannelProfile:profile]];
}

- (int)joinChannelByToken:(NSString * _Nullable)token
                channelId:(NSString * _Nonnull)channelId
                     info:(NSString * _Nullable)info
                      uid:(NSUInteger)uid
              joinSuccess:(void(^ _Nullable)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed))joinSuccessBlock {
    self.joinRoomSuccessBlock = joinSuccessBlock;
    if (uid == 0) {
        uid = [self generateRandomNumberWithDigitCount:6];
    }
    return [_thunderEngine joinRoom:token roomName:channelId uid:[NSString stringWithFormat:@"%lu", (unsigned long)uid]];
}

// 随机生成Uid
- (NSUInteger)generateRandomNumberWithDigitCount:(NSInteger)count {
    NSUInteger num = pow(10, count) - 1 - pow(10, count - 1) + 1;
    NSUInteger uidNumber = (NSUInteger)(pow(10, count - 1) + (arc4random() % num));
    return uidNumber;
}

- (int)joinChannelByUserAccount:(NSString * _Nonnull)userAccount
                          token:(NSString * _Nullable)token
                      channelId:(NSString * _Nonnull)channelId
                    joinSuccess:(void(^ _Nullable)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed))joinSuccessBlock {
    self.joinRoomSuccessBlock = joinSuccessBlock;
    NSUInteger uid = [self generateRandomNumberWithDigitCount:6];
    self.localAccount = userAccount;
    return [_thunderEngine joinRoom:token roomName:channelId uid:[NSString stringWithFormat:@"%lu", (unsigned long)uid]];
}

- (int)registerLocalUserAccount:(NSString * _Nonnull)userAccount
                          appId:(NSString * _Nonnull)appId {
    _localAccount = userAccount;
    return 1;
}

- (AgoraUserInfo* _Nullable)getUserInfoByUserAccount:(NSString * _Nonnull)userAccount
                                           withError:(AgoraErrorCode * _Nullable)error {
    if (!_localAccount) {
        return NULL;
    }

    AgoraUserInfo* userInfo = [[AgoraUserInfo alloc] init];
    userInfo.uid = _localIntUid;
    userInfo.userAccount = _localAccount;
    return userInfo;
}

- (int)leaveChannel:(void(^ _Nullable)(AgoraChannelStats * _Nonnull stat))leaveChannelBlock {
    [self clearStatus];
    return [_thunderEngine leaveRoom];
}

- (int)renewToken:(NSString * _Nonnull)token {
    return [_thunderEngine updateToken:token];
}

#pragma mark Core Audio
- (int)enableAudio {
    _audioEnabled = true;
    if (_roomJoined) {
        [self thunderEnableAudio:true];
    }
    return 0;
}

- (int)disableAudio {
    _audioEnabled = false;
    if (_roomJoined) {
        [self thunderEnableAudio:false];
    }
    return 0;
}

- (void)thunderEnableAudio:(BOOL)enabled {
    [_thunderEngine stopAllRemoteAudioStreams:!enabled];
    [_thunderEngine stopLocalAudioStream:!enabled];
}

- (int)setAudioProfile:(AgoraAudioProfile)profile
              scenario:(AgoraAudioScenario)scenario {
    return [_thunderEngine setAudioConfig:[TransformHelper transformAgoraAudioProfile:profile]
                               commutMode:THUNDER_COMMUT_MODE_DEFAULT
                             scenarioMode:[TransformHelper transformAgoraAudioScenario:scenario]];
}

- (int)adjustRecordingSignalVolume:(NSInteger)volume {
    return [_thunderEngine setMicVolume:volume];
}

- (int)enableLocalAudio:(BOOL)enabled {
    return [_thunderEngine stopLocalAudioStream:!enabled];
}

- (int)muteLocalAudioStream:(BOOL)mute {
    return [_thunderEngine stopLocalAudioStream:mute];
}

- (int)muteRemoteAudioStream:(NSUInteger)uid mute:(BOOL)mute {
    return [_thunderEngine stopRemoteAudioStream:[NSString stringWithFormat:@"%lu", (unsigned long)uid] stopped:mute];
}

- (int)muteAllRemoteAudioStreams:(BOOL)mute {
    return [_thunderEngine stopAllRemoteAudioStreams:mute];
}

- (int)adjustUserPlaybackSignalVolume:(NSUInteger)uid volume:(int)volume {
    return [_thunderEngine setPlayVolume:[NSString stringWithFormat:@"%lu", (unsigned long)uid] volume:volume];
}

#pragma mark Audio Routing Controller
- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker {
    // to do 实现效果不一定一致
    return [_thunderEngine enableLoudspeaker:defaultToSpeaker];
}

- (int)setEnableSpeakerphone:(BOOL)enableSpeaker {
    // to do 实现效果不一定一致
    return [_thunderEngine enableLoudspeaker:enableSpeaker];
}

- (BOOL)isSpeakerphoneEnabled {
    return [_thunderEngine isLoudspeakerEnabled];
}

#pragma mark In Ear Monitor
- (int)enableInEarMonitoring:(BOOL)enabled {
    return [_thunderEngine setEnableInEarMonitor:enabled];
}

#pragma mark Audio Sound Effect
- (int)setLocalVoicePitch:(double)pitch {
    return [_thunderEngine setVoicePitch:[TransformHelper transformPitch:pitch]];
}

- (int)setLocalVoiceReverbPreset:(AgoraAudioReverbPreset)reverbPreset {
    // 无返回值
    [_thunderEngine setSoundEffect:[TransformHelper transformAgoraAudioReverbPreset:reverbPreset]];
    return 0;
}

- (int)setRemoteVoicePosition:(NSUInteger) uid
                           pan:(double) pan
                          gain:(double) gain {
    return [_thunderEngine setRemoteUidVoicePosition:[NSString stringWithFormat:@"%lu", (unsigned long)uid]
                                             azimuth:(NSInteger)(pan * 90)
                                                gain:(NSInteger)(gain)];
}

// call before join
- (int)enableSoundPositionIndication:(BOOL)enabled {
    return [_thunderEngine enableVoicePosition:enabled];
}
#pragma mark audio play
// 没有返回值
- (int)startAudioMixing:(NSString *  _Nonnull)filePath
               loopback:(BOOL)loopback
                replace:(BOOL)replace
                  cycle:(NSInteger)cycle {
    // workaround
    [self.audioMixer open:filePath];
    [self.audioMixer enablePublish:true];
    [self.audioMixer setLooping:(int)cycle];
    
//    [self.audioMixer play];
    
    if (replace) {
        [_thunderEngine setAudioSourceType:THUNDER_AUDIO_FILE];
    } else {
        [_thunderEngine setAudioSourceType:THUNDER_AUDIO_MIX];
    }
    
    if (loopback) {
        if (replace) {
            [_thunderEngine setAudioSourceType:THUNDER_SOURCE_TYPE_NONE];
        } else {
            [_thunderEngine setAudioSourceType:THUNDER_AUDIO_MIC];
        }
    }
    
    return 0;
}

- (int)stopAudioMixing {
    [self.audioMixer stop];
    [_thunderEngine setAudioSourceType:THUNDER_AUDIO_MIC];
    return 0;
}

- (int)pauseAudioMixing {
    [self.audioMixer pause];
    return 0;
}

- (int)resumeAudioMixing {
    [self.audioMixer resume];
    return 0;
}

- (int)adjustAudioMixingVolume:(NSInteger)volume {
    [self.audioMixer setPlayVolume:(uint32_t)volume];
    return 0;
}

- (int)adjustAudioMixingPlayoutVolume:(NSInteger)volume {
    return [self.audioMixer setPlayerLocalVolume:(uint32_t)volume];
}

- (int)adjustAudioMixingPublishVolume:(NSInteger)volume {
    return [self.audioMixer setPlayerPublishVolume:(uint32_t)volume];
}

- (int)getAudioMixingPublishVolume {
    return [self.audioMixer getPlayerPublishVolume];
}

- (int)getAudioMixingPlayoutVolume {
    return [self.audioMixer getPlayerLocalVolume];
}

- (int)getAudioMixingDuration {
    return [self.audioMixer getTotalPlayTimeMS];
}

- (int)getAudioMixingCurrentPosition {
    return [self.audioMixer getCurrentPlayTimeMS];
}

- (int)setAudioMixingPosition:(NSInteger)pos {
    [self.audioMixer seek:(uint32_t)pos];
    return 0;
}

- (int)setAudioMixingPitch:(NSInteger)pitch {
    [self.audioMixer setSemitone:(int)(pitch / 12 * 5)];
    return 0;
}

#pragma mark audio effect (workaround)
- (int)setClientRole:(AgoraClientRole)role {
    self.agoraClientRole = role;
    return 0;
}

- (double)getEffectsVolume {
    return _allEffectsVolume;
}

- (int)setEffectsVolume:(double)volume {
    for (ThunderAudioFilePlayer* player in [[self audioEffectPlayers] allValues]) {
        [player setPlayVolume:(int32_t)volume];
    }
    _allEffectsVolume = volume;
    return 0;
}

- (int)setVolumeOfEffect:(int)soundId
              withVolume:(double)volume {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [[self audioEffectPlayers] valueForKey:soundKey];
    if (player) {
        [player setPlayVolume:(int32_t)volume];
        return 0;
    }
    return -1;
}

- (int)playEffect:(int)soundId
         filePath:(NSString * _Nullable)filePath
        loopCount:(int)loopCount
            pitch:(double)pitch
              pan:(double)pan
             gain:(double)gain
          publish:(BOOL)publish {
    // workaround
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [self.audioEffectPlayers valueForKey:soundKey];
    if (!player) {
        player = [_thunderEngine createAudioFilePlayer];
        [player setPlayerDelegate:self];
        [player open:filePath];
        [self.audioEffectPlayers setValue:player forKey:soundKey];
    }
    int count = -1;
    if (loopCount == 0) {
        count = 1;
    } else if (loopCount == 1) {
        count = 2;
    }
    // loop
    [player setLooping:count];
    // pitch
    [player setSemitone:[TransformHelper transformPitch:pitch]];
    // 方向
    [player setPosition:(int)(pan * 90)];
    // gain
    [player setPlayVolume:(uint32_t)(gain * 4)];
    // publish
    [player enablePublish:publish];
    
    // workaround play
    [self.shouldPlayEffectPlayers addObject:player];
    [player play];
    return 0;
}

- (int)stopEffect:(int)soundId {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [self.audioEffectPlayers valueForKey:soundKey];
    if (player) {
        [player stop];
        return 0;
    }
    return -1;
}

- (int)stopAllEffects {
    for (ThunderAudioFilePlayer* player in [self.audioEffectPlayers allValues]) {
        [player stop];
    }
    return 0;
}

- (int)preloadEffect:(int)soundId
            filePath:(NSString * _Nullable)filePath {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [self.audioEffectPlayers valueForKey:soundKey];
    if (!player) {
        player = [_thunderEngine createAudioFilePlayer];
        [player open:filePath];
        [self.audioEffectPlayers setValue:player forKey:soundKey];
    }
    [player open:filePath];
    return 0;
}

- (int)unloadEffect:(int)soundId {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [self.audioEffectPlayers valueForKey:soundKey];
    if (player) {
        [_thunderEngine destroyAudioFilePlayer:player];
    }
    return 0;
}

- (int)pauseEffect:(int)soundId {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [[self audioEffectPlayers] valueForKey:soundKey];
    if (player) {
        [player pause];
        return 0;
    }
    return -1;
}

- (int)pauseAllEffects {
    for (ThunderAudioFilePlayer* player in [[self audioEffectPlayers] allValues]) {
        [player pause];
    }
    return 0;
}

- (int)resumeEffect:(int)soundId {
    NSString* soundKey = [NSString stringWithFormat:@"%d", soundId];
    ThunderAudioFilePlayer* player = [[self audioEffectPlayers] valueForKey:soundKey];
    if (player) {
        [player resume];
        return 0;
    }
    return -1;
}

- (int)resumeAllEffects {
    for (ThunderAudioFilePlayer* player in [[self audioEffectPlayers] allValues]) {
        [player resume];
    }
    return 0;
}

#pragma mark Core Video
- (int)enableVideo {
    _videoEnabled = true;
    if (self.roomJoined) {
        [self thunderEnableVideo:true];
    }
    return 0;
}

- (int)disableVideo {
    _videoEnabled = false;
    if (self.roomJoined) {
        [self thunderEnableVideo:false];
    }
    return 0;
}

- (void)thunderEnableVideo:(BOOL)enabled {
    [_thunderEngine enableLocalVideoCapture:enabled];
    [_thunderEngine stopAllRemoteVideoStreams:!enabled];
    [_thunderEngine stopLocalVideoStream:!enabled];
}



- (int)setupLocalVideo:(AgoraRtcVideoCanvas * _Nullable)local {
    return [_thunderEngine setLocalVideoCanvas:[TransformHelper transformAgoraVideoCanvas:local]];
}

- (int)setupRemoteVideo:(AgoraRtcVideoCanvas * _Nonnull)remote {
    return [_thunderEngine setRemoteVideoCanvas:[TransformHelper transformAgoraVideoCanvas:remote]];
}

- (int)startPreview {
    return [_thunderEngine startVideoPreview];
}

- (int)stopPreview {
    return [_thunderEngine stopVideoPreview];
}

- (int)enableLocalVideo:(BOOL)enabled {
    [_thunderEngine enableLocalVideoCapture:enabled];
    return [_thunderEngine stopLocalVideoStream:!enabled];
}

- (int)muteLocalVideoStream:(BOOL)mute {
    return [_thunderEngine stopLocalVideoStream:mute];
}

- (int)muteAllRemoteVideoStreams:(BOOL)mute {
    return [_thunderEngine stopAllRemoteVideoStreams:mute];
}

- (int)muteRemoteVideoStream:(NSUInteger)uid
                        mute:(BOOL)mute {
    return [_thunderEngine stopRemoteVideoStream:[NSString stringWithFormat:@"%lu", (unsigned long)uid] stopped:mute];
}

#pragma mark workaround
- (AgoraConnectionStateType)getConnectionState {
    // workaround
    return [TransformHelper transformThunderConnectionState:[_thunderEngine getConnectionStatus]];
}

- (int)setDefaultMuteAllRemoteVideoStreams:(BOOL)mute {
    // workaround 与声网行为不完全一致
    return [_thunderEngine stopAllRemoteVideoStreams:mute];
}

- (int)setDefaultMuteAllRemoteAudioStreams:(BOOL)mute {
    // workaround 和声网接口行为不完全一致
    return [_thunderEngine stopAllRemoteAudioStreams:mute];
}

- (int)setLogFilter:(NSUInteger)filter {
    [_thunderEngine setLogLevel:[TransformHelper transformAgoraLogFilter:(AgoraLogFilter)filter]];
    if (filter == AgoraLogFilterOff) {
        // workaround for AgoraLogFilterOff
        [_thunderEngine setLogCallback:NULL];
    }
    return 0;
}

- (int)adjustPlaybackSignalVolume:(NSInteger)volume {
    // workaround 无此接口，本地维护列表
    for (NSString* uid in self.remoteUidArray) {
        [_thunderEngine setPlayVolume:uid volume:volume];
    }
    return 0;
}

- (int)setLocalRenderMode:(AgoraVideoRenderMode) renderMode
               mirrorMode:(AgoraVideoMirrorMode) mirrorMode {
    
    // workaround 缺少参数
    [_thunderEngine setLocalCanvasScaleMode:[TransformHelper transformAgoraVideoRenderMode:renderMode]];
    ThunderVideoMirrorMode thunderMirror = [TransformHelper transformAgoraMirrorMode:mirrorMode];
    if (thunderMirror == -1) {
        return 0;
    }
    return [_thunderEngine setLocalVideoMirrorMode:thunderMirror];
}

- (int)setRemoteRenderMode:(NSUInteger)uid
                renderMode:(AgoraVideoRenderMode) renderMode
                mirrorMode:(AgoraVideoMirrorMode) mirrorMode {
    // 缺少接口
    return [_thunderEngine setRemoteCanvasScaleMode:[NSString stringWithFormat:@"%lu", (unsigned long)uid] mode:[TransformHelper transformAgoraVideoRenderMode:renderMode]];
}

- (int)setVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration * _Nonnull)config {
    // workaround
    ThunderVideoEncoderConfiguration* thunderConfig = [[ThunderVideoEncoderConfiguration alloc] init];
    thunderConfig.publishMode = [TransformHelper transformAgoraVideoEncoderConfiguration:config];
    thunderConfig.playType = THUNDERPUBLISH_PLAY_MULTI_INTERACT;
    [_thunderEngine setVideoEncoderConfig:thunderConfig];
    [_thunderEngine setLocalVideoMirrorMode:[TransformHelper transformAgoraMirrorMode:config.mirrorMode]];
    if (config.orientationMode == AgoraVideoOutputOrientationModeAdaptative) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        [_thunderEngine setVideoCaptureOrientation:[TransformHelper transformAgoraVideoOutputOrientationMode:config.orientationMode]];
    }
    return 0;
}

- (void)orientationChanged:(NSNotification*)nitification {
    UIDevice* current = [UIDevice currentDevice];
    switch (current.orientation) {
        case UIInterfaceOrientationPortrait:
            [self.thunderEngine setVideoCaptureOrientation:THUNDER_VIDEO_CAPTURE_ORIENTATION_PORTRAIT];
            break;
            //                case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self.thunderEngine setVideoCaptureOrientation:THUNDER_VIDEO_CAPTURE_ORIENTATION_LANDSCAPE];
            break;
        default:
            break;
    }
}

- (int)setLocalVoiceEqualizationOfBandFrequency:(AgoraAudioEqualizationBandFrequency)bandFrequency withGain:(NSInteger)gain {
    // workaround
    [_thunderEngine setEnableEqualizer:true];
    gains[bandFrequency] = (float)(gain / 15.0 * 12.0);
    return [_thunderEngine setEqGains:gains];
}

- (int)setLocalVoiceReverbOfType:(AgoraAudioReverbType)reverbType withValue:(NSInteger)value {
    // workaround
    [_thunderEngine setEnableReverb:true];
    switch (reverbType) {
        case AgoraAudioReverbDryLevel:
            _reverbParam.mDryGain = value;
            break;
        case AgoraAudioReverbWetLevel:
            _reverbParam.mWetGain = value;
            break;
        case AgoraAudioReverbRoomSize:
            _reverbParam.mRoomSize = value;
            break;
        case AgoraAudioReverbWetDelay:
            _reverbParam.mPreDelay = value;
            break;
        case AgoraAudioReverbStrength:
            _reverbParam.mReverberance = value;
            break;
    }
    int code = [_thunderEngine setReverbParam:_reverbParam];
    return code;
}

#pragma mark Watermark (workaround)
- (int)addVideoWatermark:(NSURL * _Nonnull)url
                 options:(WatermarkOptions * _Nonnull)options {
    ThunderImage* thunderImage = [[ThunderImage alloc] init];
    thunderImage.url = url;
    thunderImage.rect = options.positionInPortraitMode;
    return [_thunderEngine setVideoWatermark:thunderImage];
}

- (int)clearVideoWatermarks {
    ThunderImage* thunderImage = [[ThunderImage alloc] init];
    thunderImage.url = NULL;
    return [_thunderEngine setVideoWatermark:thunderImage];
}

#pragma mark CDN Live Streaming (workaround)
- (int)addPublishStreamUrl:(NSString * _Nonnull)url transcodingEnabled:(BOOL)transcodingEnabled {
    if (transcodingEnabled) {
        [self.transcodingUrls addObject:url];
        return [_thunderEngine addPublishTranscodingStreamUrl:@"transcoding" url:url];
    } else {
        return [_thunderEngine addPublishOriginStreamUrl:url];
    }
}

- (int)removePublishStreamUrl:(NSString * _Nonnull)url {
    if ([self.transcodingUrls containsObject:url]) {
        return [_thunderEngine removePublishTranscodingStreamUrl:@"transcoding" url:url];
    } else {
        return [_thunderEngine removePublishOriginStreamUrl:url];
    }
}

- (int)setLiveTranscoding:(AgoraLiveTranscoding *_Nullable)transcoding {
    // to do
    return [_thunderEngine setLiveTranscodingTask:@"transcoding"
                                      transcoding:[TransformHelper transformAgoraLiveTranscoding:transcoding]];
}

#pragma mark 需要优化
- (int)enableAudioVolumeIndication:(NSInteger)interval
                            smooth:(NSInteger)smooth
                        report_vad:(BOOL)report_vad {
    // to do 无smooth
    return [_thunderEngine setAudioVolumeIndication:interval moreThanThd:0 lessThanThd:0 smooth:0];
}

#pragma mark to do
- (int)switchChannelByToken:(NSString * _Nullable)token
                  channelId:(NSString * _Nonnull)channelId
                joinSuccess:(void(^ _Nullable)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed))joinSuccessBlock {
    // to do
    return -1;
}



- (AgoraUserInfo* _Nullable)getUserInfoByUid:(NSUInteger)uid
                                   withError:(AgoraErrorCode * _Nullable)error {
    // to do
    return NULL;
}

- (int)startChannelMediaRelay:(AgoraChannelMediaRelayConfiguration * _Nonnull)config {
    // to do
    return -1;
}

- (int)updateChannelMediaRelay:(AgoraChannelMediaRelayConfiguration * _Nonnull)config {
    // to do
    return -1;
}

- (int)stopChannelMediaRelay {
    // to do
    return -1;
}

- (int)setBeautyEffectOptions:(BOOL)enable options:(AgoraBeautyOptions * _Nullable)options {
    // to do
    return -1;
}

- (int)enableRemoteSuperResolution:(NSUInteger)uid enabled:(BOOL)enabled {
    // to do
    return -1;
}

- (int)setInEarMonitoringVolume:(NSInteger)volume {
    // to do
    return -1;
}

- (int)setLocalVoiceChanger:(AgoraAudioVoiceChanger)voiceChanger {
    // 参数对应
    // to do
    return -1;
}

#pragma mark 自采集 (workaround)
- (void)setVideoSource:(id<AgoraVideoSourceProtocol> _Nullable)videoSource {
    if (!videoSource || [videoSource isKindOfClass:[AgoraRtcDefaultCamera class]]) {
        [_thunderEngine enableLocalVideoCapture:true];
        [_thunderEngine setCustomVideoSource:NULL];
    } else {
        [_thunderEngine enableLocalVideoCapture:false];
        _thunderVideoSource = [[CustomVideoSource alloc] init];
        _thunderVideoSource.agoraVideoSource = videoSource;
        videoSource.consumer = _thunderVideoSource;
        [_thunderEngine setCustomVideoSource:_thunderVideoSource];
    }
}

- (id<AgoraVideoSourceProtocol> _Nullable)videoSource {
    return _thunderVideoSource.agoraVideoSource;
}

#pragma mark audio recoding (workaround)
- (int)startAudioRecording:(NSString * _Nonnull)filePath
                sampleRate:(NSInteger)sampleRate
                   quality:(AgoraAudioRecordingQuality)quality {
    // workaround
    BOOL res = [_thunderEngine startAudioSaver:filePath saverMode:THUNDER_AUDIO_SAVER_BOTH fileMode:THUNDER_AUDIO_SAVER_FILE_APPEND];
    return res ? 0 : -1;
}

- (int)stopAudioRecording {
    // workaround
    BOOL res = [_thunderEngine stopAudioSaver];
    return res ? 0 : -1;
}

- (void)setAudioSessionOperationRestriction:(AgoraAudioSessionOperationRestriction)restriction {
    // to do
    return;
}

#pragma mark last mile test (to do)
- (int)startEchoTestWithInterval:(NSInteger)interval
                    successBlock:(void(^ _Nullable)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed))successBlock {
    // to do
    return -1;
}

- (int)stopEchoTest {
    // to do
    return -1;
}

- (int)enableLastmileTest {
    // to do
    return -1;
}

- (int)disableLastmileTest {
    // to do
    return -1;
}

- (int)startLastmileProbeTest:(AgoraLastmileProbeConfig *_Nullable)config {
    // to do
    return -1;
}

- (int)stopLastmileProbeTest {
    // to do
    return -1;
}

#pragma mark 自渲染（to do)
- (void)setLocalVideoRenderer:(id<AgoraVideoSinkProtocol> _Nullable)videoRenderer {
    // to do
}

- (void)setRemoteVideoRenderer:(id<AgoraVideoSinkProtocol> _Nullable)videoRenderer forUserId:(NSUInteger)userId {
    // to do
}

- (id<AgoraVideoSinkProtocol> _Nullable)localVideoRenderer {
    // to do
    return NULL;
}

- (id<AgoraVideoSinkProtocol> _Nullable)remoteVideoRendererOfUserId:(NSUInteger)userId {
    // to do
    return NULL;
}

#pragma mark External Audio Data(to do)
- (void)enableExternalAudioSink:(NSUInteger)sampleRate
                       channels:(NSUInteger)channels {
    // to do
}

- (void)disableExternalAudioSink {
    // to do
}

- (BOOL)pullPlaybackAudioFrameRawData:(void * _Nonnull)data
                         lengthInByte:(NSUInteger)lengthInByte {
    // to do
    return NO;
}

- (CMSampleBufferRef _Nullable)pullPlaybackAudioFrameSampleBufferByLengthInByte:(NSUInteger)lengthInByte {
    // to do
    return NULL;
}

- (void)enableExternalAudioSourceWithSampleRate:(NSUInteger)sampleRate
                               channelsPerFrame:(NSUInteger)channelsPerFrame {
    // to do
}

- (void)disableExternalAudioSource {
    // to do
}

- (BOOL)pushExternalAudioFrameRawData:(void * _Nonnull)data
                              samples:(NSUInteger)samples
                            timestamp:(NSTimeInterval)timestamp {
    // to do
    return NO;
}

- (BOOL)pushExternalAudioFrameSampleBuffer:(CMSampleBufferRef _Nonnull)sampleBuffer {
    // to do
    return NO;
}
 
#pragma mark External Video Data (workaround)
- (void)setExternalVideoSource:(BOOL)enable useTexture:(BOOL)useTexture pushMode:(BOOL)pushMode {
    // workaround
    if (!enable ) {
        [_thunderEngine enableLocalVideoCapture:true];
        [_thunderEngine setCustomVideoSource:NULL];
    } else {
        [_thunderEngine enableLocalVideoCapture:false];
        _thunderExternalVideoSource = [[CustomExternalVideoSource alloc] initWithUseTexture:useTexture pushMode:pushMode];
        [_thunderEngine setCustomVideoSource:_thunderExternalVideoSource];
    }
}

- (BOOL)pushExternalVideoFrame:(AgoraVideoFrame * _Nonnull)frame {
    // workaround
    return [_thunderExternalVideoSource pushExternalVideoFrame:frame];
}

#pragma mark Raw Audio Data (to do)
- (int)setRecordingAudioFrameParametersWithSampleRate:(NSInteger)sampleRate
                                              channel:(NSInteger)channel
                                                 mode:(AgoraAudioRawFrameOperationMode)mode
                                       samplesPerCall:(NSInteger)samplesPerCall {
    return [_thunderEngine setRecordingAudioFrameParameters:sampleRate
                                                    channel:channel
                                                       mode:(ThunderAudioRawFrameOperationMode)(mode + 1)
                                             samplesPerCall:samplesPerCall];
}

- (int)setPlaybackAudioFrameParametersWithSampleRate:(NSInteger)sampleRate
                                             channel:(NSInteger)channel
                                                mode:(AgoraAudioRawFrameOperationMode)mode
                                      samplesPerCall:(NSInteger)samplesPerCall {
    return [_thunderEngine setPlaybackAudioFrameParameters:sampleRate
                                                   channel:channel
                                                      mode:(ThunderAudioRawFrameOperationMode)(mode + 1)
                                            samplesPerCall:samplesPerCall];
}

- (int)setMixedAudioFrameParametersWithSampleRate:(NSInteger)sampleRate
                                   samplesPerCall:(NSInteger)samplesPerCall {
    // to do
    return -1;
}

#pragma mark Stream Fallback (to do)

- (int)setRemoteUserPriority:(NSUInteger)uid
                        type:(AgoraUserPriority)userPriority {
    // to do
    return -1;
}

- (int)setLocalPublishFallbackOption:(AgoraStreamFallbackOptions)option {
    // to do
    return -1;
}

- (int)setRemoteSubscribeFallbackOption:(AgoraStreamFallbackOptions)option {
    // to do
    return -1;
}

#pragma mark Dual-stream Mode (to do)
- (int)enableDualStreamMode:(BOOL)enabled {
    // to do
    return -1;
}

- (int)setRemoteVideoStream:(NSUInteger)uid
                       type:(AgoraVideoStreamType)streamType {
    // to do
    return -1;
}

- (int)setRemoteDefaultVideoStreamType:(AgoraVideoStreamType)streamType {
    // to do
    return -1;
}

#pragma mark Encryption (to do)
- (int)setEncryptionSecret:(NSString * _Nullable)secret {
    // to do
    return -1;
}

- (int)setEncryptionMode:(NSString * _Nullable)encryptionMode {
    // to do
    return -1;
}

#pragma mark Inject an Online Media Stream (to do restful)
- (int)addInjectStreamUrl:(NSString * _Nonnull)url config:(AgoraLiveInjectStreamConfig * _Nonnull)config {
    // to do
    return -1;
}

- (int)removeInjectStreamUrl:(NSString * _Nonnull)url {
    // to do
    return -1;
}

#pragma mark Data Stream (to do)
- (int)createDataStream:(NSInteger * _Nonnull)streamId
               reliable:(BOOL)reliable
                ordered:(BOOL)ordered {
    // to do
    return -1;
}

- (int)sendStreamMessage:(NSInteger)streamId
                    data:(NSData * _Nonnull)data {
    // to do
    return -1;
}

#pragma mark Miscellaneous Video Control (to do)

- (int)setCameraCapturerConfiguration:(AgoraCameraCapturerConfiguration * _Nullable)configuration {
    // to do
    return -1;
}

- (BOOL)isCameraZoomSupported {
    // to do
    return NO;
}

- (BOOL)isCameraTorchSupported {
    // to do
    return NO;
}

- (BOOL)isCameraFocusPositionInPreviewSupported {
    return [_thunderEngine isCameraManualFocusPositionSupported];
}

- (BOOL)isCameraExposurePositionSupported {
    return [_thunderEngine isCameraManualExposurePositionSupported];
}

- (BOOL)isCameraAutoFocusFaceModeSupported {
    // to do
    return NO;
}

- (BOOL)setCameraTorchOn:(BOOL)isOn {
    // to do
    return NO;
}

- (BOOL)setCameraAutoFocusFaceModeEnabled:(BOOL)enable {
    // to do
    return NO;
}

- (int)switchCamera {
    self.isFrontCamera = !self.isFrontCamera;
    return [_thunderEngine switchFrontCamera:self.isFrontCamera];
}

- (CGFloat)setCameraZoomFactor:(CGFloat)zoomFactor {
    return [_thunderEngine setCameraZoomFactor:zoomFactor];
}

- (BOOL)setCameraFocusPositionInPreview:(CGPoint)position {
    return [_thunderEngine setCameraFocusPosition:position];
}

- (BOOL)setCameraExposurePosition:(CGPoint)positionInView {
    return [_thunderEngine setCameraExposurePosition:positionInView];
}

#pragma mark Custom Media Metadata (to do)
- (BOOL)setMediaMetadataDataSource:(id<AgoraMediaMetadataDataSource> _Nullable) metadataDataSource withType:(AgoraMetadataType)type {
    // to do
    return NO;
}

- (BOOL)setMediaMetadataDelegate:(id<AgoraMediaMetadataDelegate> _Nullable) metadataDelegate withType:(AgoraMetadataType)type {
    // to do
    return NO;
}

#pragma mark Miscellaneous Methods (to do)

- (NSString * _Nullable)getCallId {
    // to do
    return NULL;
}

- (int)rate:(NSString * _Nonnull)callId
     rating:(NSInteger)rating
description:(NSString * _Nullable)description {
    // to do
    return -1;
}

- (int)complain:(NSString * _Nonnull)callId
    description:(NSString * _Nullable)description {
    // to do
    return -1;
}

- (int)enableMainQueueDispatch:(BOOL)enabled {
    // to do
    return -1;
}

+ (NSString * _Nonnull)getSdkVersion {
    return [ThunderEngine getVersion];
}

+ (NSString * _Nullable)getErrorDescription:(NSInteger)code {
    // to do
    return NULL;
}

- (int)setLogFileSize:(NSUInteger)fileSizeInKBytes {
    // to do
    return -1;
}

- (void * _Nullable)getNativeHandle {
    // to do
    return NULL;
}

- (int)setLogFile:(NSString * _Nonnull)filePath {
    return [_thunderEngine setLogFilePath:filePath];
}


#pragma mark Customized Methods (to do)
- (int)setParameters:(NSString * _Nonnull)options {
    // to do
    return -1;
}


- (NSString * _Nullable)getParameter:(NSString * _Nonnull)parameter
                                args:(NSString * _Nullable)args {
    // to do
    return NULL;
}

#pragma mark Deprecated Methods
- (int)setLocalRenderMode:(AgoraVideoRenderMode)mode {
    return [_thunderEngine setLocalCanvasScaleMode:[TransformHelper transformAgoraVideoRenderMode:mode]];
}

- (int)setRemoteRenderMode:(NSUInteger)uid
                      mode:(AgoraVideoRenderMode)mode {
    return [_thunderEngine setRemoteCanvasScaleMode:[NSString stringWithFormat:@"%lu", (unsigned long)uid]
                                               mode:[TransformHelper transformAgoraVideoRenderMode:mode]];
}

- (int)setLocalVideoMirrorMode:(AgoraVideoMirrorMode)mode {
    return [_thunderEngine setLocalVideoMirrorMode:[TransformHelper transformAgoraMirrorMode:mode]];
}

- (int)enableWebSdkInteroperability:(BOOL)enabled {
    return [_thunderEngine enableWebSdkCompatibility:enabled];
}

#pragma mark Thunder engine delegate
- (void)thunderEngine:(ThunderEngine * _Nonnull)engine bPublish:(BOOL)bPublish bizAuthResult:(NSInteger)bizAuthResult {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioCapturePcmData:(nullable NSData *)data sampleRate:(NSUInteger)sampleRate channel:(NSUInteger)channel {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioCaptureStatus:(NSInteger)status {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioPlayData:(nonnull NSString *)uid duration:(NSUInteger)duration cpt:(NSUInteger)cpt pts:(NSUInteger)pts data:(nullable NSData *)data {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioPlaySpectrumData:(nullable NSData *)data {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioRenderPcmData:(nullable NSData *)data duration:(NSUInteger)duration sampleRate:(NSUInteger)sampleRate channel:(NSUInteger)channel {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onAudioRouteChanged:(ThunderAudioOutputRouting)routing {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didAudioRouteChanged:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didAudioRouteChanged:(AgoraAudioOutputRouting)routing];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onCameraExposureAreaChanged:(CGRect)exposureArea {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:cameraExposureDidChangedToRect:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self cameraExposureDidChangedToRect:exposureArea];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onCameraFocusAreaChanged:(CGRect)focusArea {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:cameraFocusDidChangedToRect:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self cameraFocusDidChangedToRect:focusArea];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onCaptureVolumeIndication:(NSInteger)totalVolume cpt:(NSUInteger)cpt micVolume:(NSInteger)micVolume {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onConnectionStatus:(ThunderConnectionStatus)status {
    // to do 没有reason
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:connectionChangedToState:reason:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self connectionChangedToState:[TransformHelper transformThunderConnectionState:status] reason:AgoraConnectionChangedConnecting];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onDeviceStats:(ThunderRtcLocalDeviceStats * _Nonnull)stats {
    _deviceStats = stats;
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onEchoDetectResult:(BOOL)bEcho {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onFirstLocalAudioFrameSent:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:firstLocalAudioFrame:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self firstLocalAudioFrame:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onFirstLocalVideoFrameSent:(NSInteger)elapsed {
    // to do 没有size
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:firstLocalVideoFrameWithSize:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self firstLocalVideoFrameWithSize:CGSizeZero elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onHowlingDetectResult:(BOOL)bHowling {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onJoinRoomSuccess:(nonnull NSString *)room withUid:(nonnull NSString *)uid elapsed:(NSInteger)elapsed {
    _localIntUid = uid.integerValue;
    self.roomJoined = true;
    
    if (self.joinRoomSuccessBlock) {
        self.joinRoomSuccessBlock(room, uid.integerValue, elapsed);
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didJoinChannel:withUid:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didJoinChannel:room withUid:uid.integerValue elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLeaveRoomWithStats:(ThunderRtcRoomStats * _Nonnull)stats {
    AgoraChannelStats* channelStats = [TransformHelper paddingChannelStats:_thunderRoomStats deviceStats:_deviceStats];
    channelStats.userCount = self.remoteUidArray.count + 1;
    if (_leaveChannelBlock) {
        _leaveChannelBlock(channelStats);
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didLeaveChannelWithStats:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didLeaveChannelWithStats:channelStats];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalAudioStats:(ThunderRtcLocalAudioStats * _Nonnull)stats {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:localAudioStats:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self localAudioStats:[TransformHelper transformThunderRtcLocalAudioStats:stats]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalAudioStatusChanged:(ThunderLocalAudioStreamStatus)status errorReason:(ThunderLocalAudioStreamErrorReason)errorReason {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:localAudioStateChange:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self localAudioStateChange:[TransformHelper transformThunderLocalAudioStreamStatus:status] error:[TransformHelper transformThunderLocalAudioStreamErrorReason:errorReason]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalVideoStats:(ThunderRtcLocalVideoStats * _Nonnull)stats {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:localVideoStats:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self localVideoStats:[TransformHelper transformThunderRtcLocalVideoStats:stats]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onLocalVideoStatusChanged:(ThunderLocalVideoStreamStatus)status error:(ThunderLocalVideoStreamErrorReason)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:localVideoStateChange:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self localVideoStateChange:[TransformHelper transformThunderLocalVideoStreamStatus:status] error:[TransformHelper transformThunderLocalVideoStreamErrorReason:error]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onNetworkQuality:(nonnull NSString *)uid txQuality:(ThunderLiveRtcNetworkQuality)txQuality rxQuality:(ThunderLiveRtcNetworkQuality)rxQuality {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:networkQuality:txQuality:rxQuality:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self networkQuality:uid.integerValue txQuality:[TransformHelper transformThunderLiveRtcNetworkQuality:txQuality] rxQuality:[TransformHelper transformThunderLiveRtcNetworkQuality:rxQuality]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onNetworkTypeChanged:(NSInteger)type {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:networkTypeChangedToType:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self networkTypeChangedToType:[TransformHelper transformThunderNetworkType:(ThunderNetworkType)type]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onPlayVolumeIndication:(NSArray<ThunderRtcAudioVolumeInfo *> * _Nonnull)speakers totalVolume:(NSInteger)totalVolume {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:reportAudioVolumeIndicationOfSpeakers:totalVolume:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self reportAudioVolumeIndicationOfSpeakers:[TransformHelper transformThunderSpeakersInfo:speakers] totalVolume:totalVolume];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onPublishStreamToCDNStatusWithUrl:(NSString * _Nonnull)url errorCode:(ThunderPublishCDNErrorCode)errorCode {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:streamPublishedWithUrl:errorCode:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self streamPublishedWithUrl:url errorCode:[TransformHelper transformThunderPublishCDNErrorCode:errorCode]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRecvUserAppMsgData:(nonnull NSData *)msgData uid:(nonnull NSString *)uid {
    // to do 缺少streamId
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:receiveStreamMessageFromUid:streamId:data:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self receiveStreamMessageFromUid:uid.integerValue streamId:0 data:msgData];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioPlay:(nonnull NSString *)uid elapsed:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:firstRemoteAudioFrameOfUid:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self firstRemoteAudioFrameOfUid:uid.integerValue elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioStateChangedOfUid:(nonnull NSString *)uid state:(ThunderRemoteAudioState)state reason:(ThunderRemoteAudioReason)reason elapsed:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:remoteAudioStateChangedOfUid:state:reason:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self remoteAudioStateChangedOfUid:uid.integerValue state:[TransformHelper transformThunderRemoteAudioState:state] reason:[TransformHelper transformThunderRemoteAudioReason:reason] elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioStatsOfUid:(nonnull NSString *)uid stats:(ThunderRtcRemoteAudioStats * _Nonnull)stats {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:remoteAudioStats:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self remoteAudioStats:[TransformHelper transformThunderRtcRemoteAudioStats:stats withUid:uid.integerValue]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteAudioStopped:(BOOL)stopped byUid:(nonnull NSString *)uid {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didAudioMuted:byUid:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didAudioMuted:stopped byUid:uid.integerValue];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoPlay:(nonnull NSString *)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:firstRemoteVideoFrameOfUid:size:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self firstRemoteVideoFrameOfUid:uid.integerValue size:size elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoStateChangedOfUid:(nonnull NSString *)uid state:(ThunderRemoteVideoState)state reason:(ThunderRemoteVideoReason)reason elapsed:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:remoteVideoStateChangedOfUid:state:reason:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self remoteVideoStateChangedOfUid:uid.integerValue state:[TransformHelper transformThunderRemoteVideoState:state] reason:[TransformHelper transformThunderRemoteVideoReason:reason] elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoStatsOfUid:(nonnull NSString *)uid stats:(ThunderRtcRemoteVideoStats * _Nonnull)stats {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:remoteVideoStats:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self remoteVideoStats:[TransformHelper transformThunderRtcRemoteVideoStats:stats withUid:uid.integerValue]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRemoteVideoStopped:(BOOL)stopped byUid:(nonnull NSString *)uid {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didVideoMuted:byUid:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didVideoMuted:stopped byUid:uid.integerValue];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onRoomStats:(nonnull RoomStats *)stats {
    _thunderRoomStats = stats;
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:reportRtcStats:)]) {
        AgoraChannelStats* channelStats = [TransformHelper paddingChannelStats:self.thunderRoomStats deviceStats:self.deviceStats];
        channelStats.userCount = self.remoteUidArray.count + 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self reportRtcStats:channelStats];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onSendAppMsgDataFailedStatus:(NSUInteger)status {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onTokenWillExpire:(nonnull NSString *)token {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:tokenPrivilegeWillExpire:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self tokenPrivilegeWillExpire:token];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserBanned:(BOOL)status {
    // to do 不一定对
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngineConnectionDidBanned:)] && status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngineConnectionDidBanned:self];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserJoined:(nonnull NSString *)uid elapsed:(NSInteger)elapsed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didJoinedOfUid:elapsed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didJoinedOfUid:uid.integerValue elapsed:elapsed];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onUserOffline:(nonnull NSString *)uid reason:(ThunderLiveRtcUserOfflineReason)reason {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:didOfflineOfUid:reason:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self didOfflineOfUid:uid.integerValue reason:[TransformHelper transformThunderLiveRtcUserOfflineReason:reason]];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onVideoCaptureStatus:(ThunderVideoCaptureStatus)status {
    
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine onVideoSizeChangedOfUid:(nonnull NSString *)uid size:(CGSize)size rotation:(NSInteger)rotation {
    if (uid.integerValue != _localIntUid && ![self.videoDecodedSet containsObject:uid] && self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:firstRemoteVideoDecodedOfUid:size:elapsed:)]) {
//        [_thunderEngine registerVideoDecodeFrameObserver:self uid:uid];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self firstRemoteVideoDecodedOfUid:uid.integerValue size:size elapsed:0];
        });
        [self.videoDecodedSet addObject:uid];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngine:videoSizeChangedOfUid:size:rotation:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngine:self videoSizeChangedOfUid:uid.integerValue size:size rotation:rotation];
        });
    }
}

- (void)thunderEngine:(ThunderEngine * _Nonnull)engine sdkAuthResult:(ThunderRtcSdkAuthResult)sdkAuthResult {
    
}

- (void)thunderEngineConnectionLost:(ThunderEngine * _Nonnull)engine {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngineConnectionDidLost:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngineConnectionDidLost:self];
        });
    }
}

- (void)thunderEngineTokenRequest:(ThunderEngine * _Nonnull)engine {
    if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngineRequestToken:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate rtcEngineRequestToken:self];
        });
    }
}

#pragma mark ThunderVideoDecodeFrameObserver
- (void)onVideoDecodeFrame:(CVPixelBufferRef _Nonnull)pixelBuf pts:(uint64_t)pts uid:(NSString * _Nonnull)uid {
    
}

#pragma mark ThunderAudioFilePlayerDelegate
- (void)onAudioFileStateChange:(nonnull ThunderAudioFilePlayer*)player event:(ThunderAudioFilePlayerEvent)event  errorCode:(ThunderAudioFilePLayerErrorCode)errorCode {
    if (event == AUDIO_PLAY_EVENT_OPEN) {
        if (player == self.audioMixer) {
            [player play];
            return;
        }
        if ([self.shouldPlayEffectPlayers containsObject:player]) {
            [self.shouldPlayEffectPlayers removeObject:player];
            [player play];
            return;
        }
    }
    if (event == AUDIO_PLAY_EVENT_STOP) {
        if (player == self.audioMixer) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(rtcEngineLocalAudioMixingDidFinish:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate rtcEngineLocalAudioMixingDidFinish:self];
                });
            }
        }
    }
}


- (void)onAudioFileVolume:(nonnull ThunderAudioFilePlayer*)player
                   volume:(uint32_t)volume
                currentMs:(uint32_t)currentMs
                  totalMs:(uint32_t)totalMs {
    
}

@end
