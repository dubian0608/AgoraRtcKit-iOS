//
//  TransformHelper.m
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/16.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import "TransformHelper.h"

@implementation TransformHelper

+ (ThunderVideoCanvas *)transformAgoraVideoCanvas:(AgoraRtcVideoCanvas * _Nullable)canvas {
    ThunderVideoCanvas* thunderCanvas = [[ThunderVideoCanvas alloc]init];
    thunderCanvas.view = canvas.view;
    thunderCanvas.uid = [NSString stringWithFormat:@"%lu", (unsigned long)canvas.uid];
    thunderCanvas.renderMode = [self transformAgoraVideoRenderMode:canvas.renderMode];
    
    return thunderCanvas;
}

+ (ThunderVideoRenderMode)transformAgoraVideoRenderMode:(AgoraVideoRenderMode)renderMode {
    switch (renderMode) {
        case AgoraVideoRenderModeHidden:
            return THUNDER_RENDER_MODE_CLIP_TO_BOUNDS;
        case AgoraVideoRenderModeFill:
            return THUNDER_RENDER_MODE_FILL;
        case AgoraVideoRenderModeFit:
            return THUNDER_RENDER_MODE_ASPECT_FIT;
        default:
            return THUNDER_RENDER_MODE_ASPECT_FIT;;
    }
}

+ (ThunderVideoMirrorMode)transformAgoraMirrorMode:(AgoraVideoMirrorMode)mirrorMode {
    switch (mirrorMode) {
        case AgoraVideoMirrorModeEnabled:
            return THUNDER_VIDEO_MIRROR_MODE_PREVIEW_PUBLISH_BOTH_MIRROR;
        case AgoraVideoMirrorModeDisabled:
            return THUNDER_VIDEO_MIRROR_MODE_PREVIEW_PUBLISH_BOTH_NO_MIRROR;
        default:
            return -1;;
    }
}

+ (ThunderRtcRoomConfig)transformAgoraChannelProfile:(AgoraChannelProfile)profile {
    switch (profile) {
        case AgoraChannelProfileLiveBroadcasting:
            return THUNDER_ROOM_CONFIG_LIVE;
        case AgoraChannelProfileCommunication:
            return THUNDER_ROOM_CONFIG_COMMUNICATION;
        case AgoraChannelProfileGame:
            return THUNDER_ROOM_CONFIG_GAME;
        default:
            return THUNDER_ROOM_CONFIG_LIVE;
    }
}

+ (ThunderConnectionStatus)transformAgoraConnectionStateType:(AgoraConnectionStateType)state {
    switch (state) {
        case AgoraConnectionStateDisconnected:
            return THUNDER_CONNECTION_STATUS_DISCONNECTED;
        case AgoraConnectionStateConnecting:
            return THUNDER_CONNECTION_STATUS_CONNECTING;
        case AgoraConnectionStateConnected:
            return THUNDER_CONNECTION_STATUS_CONNECTED;
        case AgoraConnectionStateReconnecting:
        case AgoraConnectionStateFailed:
        default:
            return THUNDER_CONNECTION_STATUS_CONNECTING;
    }
}

+ (ThunderRtcScenarioMode)transformAgoraAudioScenario: (AgoraAudioScenario)scenario {
    switch (scenario) {
        case AgoraAudioScenarioDefault:
            return THUNDER_SCENARIO_MODE_DEFAULT;
        case AgoraAudioScenarioShowRoom:
            return THUNDER_SCENARIO_MODE_STABLE_FIRST;
        case AgoraAudioScenarioEducation:
            return THUNDER_SCENARIO_MODE_QUALITY_FIRST;
        case AgoraAudioScenarioGameStreaming:
            return THUNDER_SCENARIO_MODE_STABLE_FIRST;
        case AgoraAudioScenarioChatRoomGaming:
            return THUNDER_SCENARIO_MODE_STABLE_FIRST;
        case AgoraAudioScenarioChatRoomEntertainment:
            return THUNDER_SCENARIO_MODE_STABLE_FIRST;
        default:
            return THUNDER_SCENARIO_MODE_DEFAULT;
    }
}

+ (ThunderRtcAudioConfig)transformAgoraAudioProfile:(AgoraAudioProfile)profile {
    switch (profile) {
        case AgoraAudioProfileDefault:
            return THUNDER_AUDIO_CONFIG_DEFAULT;
        case AgoraAudioProfileSpeechStandard:
            return THUNDER_AUDIO_CONFIG_SPEECH_STANDARD;
        case AgoraAudioProfileMusicStandard:
            return THUNDER_AUDIO_CONFIG_MUSIC_STANDARD;
        case AgoraAudioProfileMusicStandardStereo:
            return THUNDER_AUDIO_CONFIG_MUSIC_STANDARD_STEREO;
        case AgoraAudioProfileMusicHighQuality:
            // 没有单声道
            return THUNDER_AUDIO_CONFIG_MUSIC_HIGH_QUALITY_STEREO;
        case AgoraAudioProfileMusicHighQualityStereo:
            return THUNDER_AUDIO_CONFIG_MUSIC_HIGH_QUALITY_STEREO_192;
        default:
            return THUNDER_AUDIO_CONFIG_DEFAULT;
    }
}

+ (ThunderRtcSoundEffectMode)transformAgoraAudioReverbPreset:(AgoraAudioReverbPreset)reverbPreset {
    switch (reverbPreset) {
        case AgoraAudioReverbPresetOff:
            return THUNDER_SOUND_EFFECT_MODE_NONE;
        case AgoraAudioReverbPresetKTV:
        case AgoraAudioReverbPresetFxKTV:
            return THUNDER_SOUND_EFFECT_MODE_KTV;
        case AgoraAudioReverbPresetRnB:
        case AgoraAudioReverbPresetFxRNB:
            return THUNDER_SOUND_EFFECT_MODE_RANDB;
        case AgoraAudioReverbPresetRock:
            return THUNDER_SOUND_EFFECT_MODE_ROCK;
        case AgoraAudioReverbPresetHipHop:
            return THUNDER_SOUND_EFFECT_MODE_HIPHOP;
        case AgoraAudioReverbPresetStudio:
        case AgoraAudioReverbPresetFxStudio:
            return THUNDER_SOUND_EFFECT_MODE_STUDIO;
        case AgoraAudioReverbPresetPopular:
        case AgoraAudioReverbPresetFxPopular:
            return THUNDER_SOUND_EFFECT_MODE_POP;
        case AgoraAudioReverbPresetVocalConcert:
        case AgoraAudioReverbPresetFxVocalConcert:
            return THUNDER_SOUND_EFFECT_MODE_CONCERT;
        
        case AgoraAudioReverbPresetFxUncle:
        case AgoraAudioReverbPresetFxSister:
        case AgoraAudioReverbPresetFxPhonograph:
        case AgoraAudioReverbPresetVirtualStereo:
        default:
            return THUNDER_SOUND_EFFECT_MODE_NONE;
    }
}

+ (AgoraConnectionStateType)transformThunderConnectionState:(ThunderConnectionStatus)state {
    switch (state) {
        case THUNDER_CONNECTION_STATUS_CONNECTED:
            return AgoraConnectionStateConnected;
        case THUNDER_CONNECTION_STATUS_CONNECTING:
            return AgoraConnectionStateConnecting;
        case THUNDER_CONNECTION_STATUS_DISCONNECTED:
            return AgoraConnectionStateDisconnected;
        default:
            return AgoraConnectionStateConnected;
    }
}

// to do
+ (LiveTranscoding*)transformAgoraLiveTranscoding:(AgoraLiveTranscoding*)transcoding {
    LiveTranscoding* thunderTranscoding = [[LiveTranscoding alloc] init];
    
    return thunderTranscoding;
}

+ (ThunderRtcLogLevel)transformAgoraLogFilter:(AgoraLogFilter)filter {
    switch (filter) {
        case AgoraLogFilterOff:
            return THUNDER_LOG_LEVEL_ERROR;
        case AgoraLogFilterInfo:
            return THUNDER_LOG_LEVEL_INFO;
        case AgoraLogFilterError:
            return THUNDER_LOG_LEVEL_ERROR;
        case AgoraLogFilterDebug:
            return THUNDER_LOG_LEVEL_DEBUG;
        case AgoraLogFilterWarning:
            return THUNDER_LOG_LEVEL_WARN;
        case AgoraLogFilterCritical:
            return THUNDER_LOG_LEVEL_TRACE;
        default:
            return THUNDER_LOG_LEVEL_INFO;
    }
}

// to do
+ (AgoraChannelStats*)transformThunderRtcRoomStats:(ThunderRtcRoomStats*)stats {
    AgoraChannelStats* agoraStats = [[AgoraChannelStats alloc] init];
    return agoraStats;
}

+ (AgoraRtcLocalAudioStats*)transformThunderRtcLocalAudioStats:(ThunderRtcLocalAudioStats*)stats {
    AgoraRtcLocalAudioStats* agoraStats = [[AgoraRtcLocalAudioStats alloc] init];
    agoraStats.numChannels = stats.numChannels;
    agoraStats.sentSampleRate = stats.sendSampleRate;
    agoraStats.sentBitrate = stats.sendBitrate;
    return agoraStats;
}

+ (AgoraAudioLocalState)transformThunderLocalAudioStreamStatus:(ThunderLocalAudioStreamStatus)status {
    switch (status) {
        case THUNDER_LOCAL_AUDIO_STREAM_STATUS_CAPTURING:
            return AgoraAudioLocalStateRecording;
        case THUNDER_LOCAL_AUDIO_STREAM_STATUS_STOPPED:
            return AgoraAudioLocalStateStopped;
        case THUNDER_LOCAL_AUDIO_STREAM_STATUS_ENCODING:
            return AgoraAudioLocalStateEncoding;
        case THUNDER_LOCAL_AUDIO_STREAM_STATUS_FAILED:
            return AgoraAudioLocalStateFailed;
        case THUNDER_LOCAL_AUDIO_STREAM_STATUS_SENDING:
        default:
            return AgoraAudioLocalStateEncoding;;
    }
    return AgoraAudioLocalStateEncoding;
}

+ (AgoraAudioLocalError)transformThunderLocalAudioStreamErrorReason:(ThunderLocalAudioStreamErrorReason)error {
    switch (error) {
        case THUNDER_LOCAL_AUDIO_STREAM_ERROR_OK:
            return AgoraAudioLocalErrorOk;
        case THUNDER_LOCAL_AUDIO_STREAM_ERROR_UNKNOWN:
            return AgoraAudioLocalErrorFailure;
        case THUNDER_LOCAL_AUDIO_STREAM_ERROR_CAPTURE_FAILURE:
            return AgoraAudioLocalErrorRecordFailure;
        case THUNDER_LOCAL_AUDIO_STREAM_ERROR_ENCODE_FAILURE:
            return AgoraAudioLocalErrorEncodeFailure;
        default:
            return AgoraAudioLocalErrorOk;
    }
}

+ (AgoraRtcLocalVideoStats*)transformThunderRtcLocalVideoStats:(ThunderRtcLocalVideoStats*)stats {
    AgoraRtcLocalVideoStats* videoStats = [[AgoraRtcLocalVideoStats alloc] init];
    videoStats.sentBitrate = stats.sendBitrate;
    videoStats.sentFrameRate = stats.sendFrameRate;
    videoStats.encoderOutputFrameRate = stats.encoderOutputFrameRate;
    videoStats.rendererOutputFrameRate = stats.renderOutputFrameRate;
    videoStats.sentTargetBitrate = stats.targetBitrate;
    videoStats.sentTargetFrameRate = stats.targetFrameRate;
    videoStats.qualityAdaptIndication = (AgoraVideoQualityAdaptIndication)stats.qualityAdaptIndication;
    videoStats.encodedBitrate = stats.encodedBitrate;
    videoStats.encodedFrameWidth = stats.encodedFrameWidth;
    videoStats.encodedFrameHeight = stats.encodedFrameHeight;
    videoStats.encodedFrameCount = stats.encodedFrameCount;
    videoStats.codecType = [TransformHelper transformThunderVideoCodecType:stats.codecType];
    return videoStats;
}

+ (AgoraVideoCodecType)transformThunderVideoCodecType:(ThunderVideoCodecType)type {
    switch (type) {
        case ThunderVideoCodecTypeVP8:
            return AgoraVideoCodecTypeVP8;
        case ThunderVideoCodecTypeH264:
            return AgoraVideoCodecTypeH264;
        default:
            return AgoraVideoCodecTypeVP8;;
    }
}

+ (AgoraLocalVideoStreamState)transformThunderLocalVideoStreamStatus:(ThunderLocalVideoStreamStatus)status {
    switch (status) {
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_STOPPED:
            return AgoraLocalVideoStreamStateStopped;
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_CAPTURING:
            return AgoraLocalVideoStreamStateCapturing;
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_ENCODING:
            return AgoraLocalVideoStreamStateEncoding;
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_FAILED:
            return AgoraLocalVideoStreamStateFailed;
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_SENDING:
        case THUNDER_LOCAL_VIDEO_STREAM_STATUS_PREVIEWING:
        default:
            return AgoraLocalVideoStreamStateCapturing;
    }
}

+ (AgoraLocalVideoStreamError)transformThunderLocalVideoStreamErrorReason:(ThunderLocalVideoStreamErrorReason)error {
    return (AgoraLocalVideoStreamError)error;
}

+ (AgoraNetworkQuality)transformThunderLiveRtcNetworkQuality:(ThunderLiveRtcNetworkQuality)quality {
    switch (quality) {
        case THUNDER_SDK_NETWORK_QUALITY_UNKNOWN:
            return AgoraNetworkQualityUnknown;
        case THUNDER_SDK_NETWORK_QUALITY_EXCELLENT:
            return AgoraNetworkQualityExcellent;
        case THUNDER_SDK_NETWORK_QUALITY_GOOD:
            return AgoraNetworkQualityGood;
        case THUNDER_SDK_NETWORK_QUALITY_POOR:
            return AgoraNetworkQualityPoor;
        case THUNDER_SDK_NETWORK_QUALITY_BAD:
            return AgoraNetworkQualityBad;
        case THUNDER_SDK_NETWORK_QUALITY_VBAD:
            return AgoraNetworkQualityVBad;
        case THUNDER_SDK_NETWORK_QUALITY_DOWN:
            return AgoraNetworkQualityDown;
        default:
            return AgoraNetworkQualityUnknown;
    }
}

+ (AgoraNetworkType)transformThunderNetworkType:(ThunderNetworkType)type {
    switch (type) {
        case THUNDER_NETWORK_TYPE_UNKNOWN:
            return AgoraNetworkTypeUnknown;
        case THUNDER_NETWORK_TYPE_DISCONNECTED:
            return AgoraNetworkTypeDisconnected;
        case THUNDER_NETWORK_TYPE_CABLE:
            return AgoraNetworkTypeLAN;
        case THUNDER_NETWORK_TYPE_WIFI:
            return AgoraNetworkTypeWIFI;
        case THUNDER_NETWORK_TYPE_MOBILE_2G:
            return AgoraNetworkTypeMobile2G;
        case THUNDER_NETWORK_TYPE_MOBILE_3G:
            return AgoraNetworkTypeMobile3G;
        case THUNDER_NETWORK_TYPE_MOBILE_4G:
            return AgoraNetworkTypeMobile4G;
        case THUNDER_NETWORK_TYPE_MOBILE:
        default:
            return AgoraNetworkTypeUnknown;
    }
}

+ (NSArray<AgoraRtcAudioVolumeInfo *> *)transformThunderSpeakersInfo:(NSArray<ThunderRtcAudioVolumeInfo *> *)speakers {
    NSMutableArray<AgoraRtcAudioVolumeInfo *> * agoraSpeaks = [[NSMutableArray alloc] init];
    for (ThunderRtcAudioVolumeInfo * info in speakers) {
        AgoraRtcAudioVolumeInfo* agoraInfo = [TransformHelper transformThunderRtcAudioVolumeInfo:info];
        [agoraSpeaks addObject:agoraInfo];
    }
    return [agoraSpeaks copy];
}

+ (AgoraRtcAudioVolumeInfo*)transformThunderRtcAudioVolumeInfo:(ThunderRtcAudioVolumeInfo*)info {
    AgoraRtcAudioVolumeInfo* agoraInfo = [[AgoraRtcAudioVolumeInfo alloc] init];
    agoraInfo.uid = info.uid.integerValue;
    agoraInfo.volume = info.volume;
    
    return agoraInfo;
}

+ (AgoraErrorCode)transformThunderPublishCDNErrorCode:(ThunderPublishCDNErrorCode)errorCode {
    switch (errorCode) {
        case THUNDER_PUBLISH_CDN_ERR_TOCDN_FAILED:
            return AgoraErrorCodePublishStreamCDNError;
        case THUNDER_PUBLISH_CDN_ERR_THUNDERSERVER_FAILED:
            return AgoraErrorCodePublishStreamInternalServerError;
        case THUNDER_PUBLISH_CDN_ERR_THUNDERSERVER_STOP:
            return AgoraErrorCodePublishStreamInternalServerError;
        case THUNDER_PUBLISH_CDN_ERR_SUCCESS:
        default:
            return AgoraErrorCodeNoError;;
    }
}

+ (AgoraAudioRemoteState)transformThunderRemoteAudioState:(ThunderRemoteAudioState)state {
    return (AgoraAudioRemoteState)state;
}

+ (AgoraAudioRemoteStateReason)transformThunderRemoteAudioReason:(ThunderRemoteAudioReason)reason {
    switch (reason) {
        case THUNDER_REMOTE_AUDIO_REASON_INTERNAL:
            return AgoraAudioRemoteReasonInternal;
        case THUNDER_REMOTE_AUDIO_REASON_NETWORK_CONGESTION:
            return AgoraAudioRemoteReasonNetworkCongestion;
        case THUNDER_REMOTE_AUDIO_REASON_NETWORK_RECOVERY:
            return AgoraAudioRemoteReasonNetworkRecovery;
        case THUNDER_REMOTE_AUDIO_REASON_LOCAL_STOPPED:
            return AgoraAudioRemoteReasonLocalMuted;
        case THUNDER_REMOTE_AUDIO_REASON_LOCAL_STARTED:
            return AgoraAudioRemoteReasonLocalUnmuted;
        case THUNDER_REMOTE_AUDIO_REASON_REMOTE_STOPPED:
            return AgoraAudioRemoteReasonRemoteMuted;
        case THUNDER_REMOTE_AUDIO_REASON_REMOTE_STARTED:
            return AgoraAudioRemoteReasonRemoteUnmuted;
        case THUNDER_REMOTE_AUDIO_REASON_FORMAT_NOT_SUPPORT:
        case THUNDER_REMOTE_AUDIO_REASON_PLAY_DEVICE_START_FAILED:
        case THUNDER_REMOTE_AUDIO_REASON_OK:
        default:
            return AgoraAudioRemoteReasonInternal;
    }
}

+ (AgoraRtcRemoteAudioStats*)transformThunderRtcRemoteAudioStats:(ThunderRtcRemoteAudioStats*)stats withUid:(NSInteger)uid {
    AgoraRtcRemoteAudioStats* audioStats = [[AgoraRtcRemoteAudioStats alloc] init];
    audioStats.uid = uid;
    audioStats.quality = stats.quality;
    audioStats.networkTransportDelay = stats.networkTransportDelay;
    audioStats.jitterBufferDelay = stats.jitterBufferDelay;
    audioStats.audioLossRate = stats.frameLossRate;
    audioStats.numChannels = stats.numChannels;
    audioStats.receivedSampleRate = stats.receivedSampleRate;
    audioStats.receivedBitrate = stats.receivedBitrate;
    audioStats.totalFrozenTime = stats.totalFrozenTime;
    audioStats.frozenRate = stats.frozenRate;
    // to do 缺少totalActiveTime
    audioStats.totalActiveTime = 0;
    return audioStats;
}

+ (AgoraVideoRemoteState)transformThunderRemoteVideoState:(ThunderRemoteVideoState)stats {
    switch (stats) {
        case THUNDER_REMOTE_VIDEO_STATE_STOPPED:
            return AgoraVideoRemoteStateStopped;
        case THUNDER_REMOTE_VIDEO_STATE_STARTING:
            return AgoraVideoRemoteStateStarting;
        case THUNDER_REMOTE_VIDEO_STATE_DECODING:
            return AgoraVideoRemoteStateDecoding;
        case THUNDER_REMOTE_VIDEO_STATE_FROZEN:
            return AgoraVideoRemoteStateFrozen;
        case THUNDER_REMOTE_VIDEO_STATE_RENDERING:
        default:
            return AgoraVideoRemoteStateDecoding;
    }
}

+ (AgoraVideoRemoteStateReason)transformThunderRemoteVideoReason:(ThunderRemoteVideoReason)reason {
    switch (reason) {
        case THUNDER_REMOTE_VIDEO_REASON_INTERNAL:
            return AgoraVideoRemoteStateReasonInternal;
        case THUNDER_REMOTE_VIDEO_REASON_NETWORK_CONGESTION:
            return AgoraVideoRemoteStateReasonNetworkCongestion;
        case THUNDER_REMOTE_VIDEO_REASON_NETWORK_RECOVERY:
            return AgoraVideoRemoteStateReasonNetworkRecovery;
        case THUNDER_REMOTE_VIDEO_REASON_LOCAL_STOPPED:
            return AgoraVideoRemoteStateReasonLocalMuted;
        case THUNDER_REMOTE_VIDEO_REASON_LOCAL_STARTED:
            return AgoraVideoRemoteStateReasonLocalUnmuted;
        case THUNDER_REMOTE_VIDEO_REASON_REMOTE_STOPPED:
            return AgoraVideoRemoteStateReasonRemoteMuted;
        case THUNDER_REMOTE_VIDEO_REASON_REMOTE_STARTED:
            return AgoraVideoRemoteStateReasonRemoteUnmuted;
        case THUNDER_REMOTE_VIDEO_REASON_OK:
        default:
            return AgoraVideoRemoteStateReasonInternal;
    }
}

+ (AgoraRtcRemoteVideoStats*)transformThunderRtcRemoteVideoStats:(ThunderRtcRemoteVideoStats*)stats withUid:(NSInteger)uid {
    AgoraRtcRemoteVideoStats* videoStats = [[AgoraRtcRemoteVideoStats alloc] init];
    videoStats.uid = uid;
    videoStats.delay = stats.delay;
    videoStats.width = stats.width;
    videoStats.height = stats.height;
    videoStats.receivedBitrate = stats.receivedBitrate;
    videoStats.decoderOutputFrameRate = stats.decoderOutputFrameRate;
    videoStats.rendererOutputFrameRate = stats.rendererOutputFrameRate;
    videoStats.packetLossRate = stats.packetLossRate;
    videoStats.rxStreamType = stats.rxStreamType;
    videoStats.totalFrozenTime = stats.totalFrozenTime;
    videoStats.frozenRate = stats.frozenRate;
    videoStats.totalActiveTime = 0;
    return videoStats;
}

+ (AgoraUserOfflineReason)transformThunderLiveRtcUserOfflineReason:(ThunderLiveRtcUserOfflineReason)reason {
    switch (reason) {
        case THUNDER_SDK_USER_OFF_LINE_REASON_QUIT:
            return AgoraUserOfflineReasonQuit;
        case THUNDER_SDK_USER_OFF_LINE_REASON_DROPPED:
            return AgoraUserOfflineReasonDropped;
        case THUNDER_SDK_USER_OFF_LINE_REASON_BECOME_AUDIENCE:
            return AgoraUserOfflineReasonBecomeAudience;
        default:
            return AgoraUserOfflineReasonQuit;
    }
}

+ (AgoraChannelStats*)paddingChannelStats:(RoomStats* _Nullable)roomStats deviceStats:(ThunderRtcLocalDeviceStats* _Nullable)deviceStats {
    AgoraChannelStats* channelStats = [[AgoraChannelStats alloc] init];
    
    if (roomStats) {
        channelStats.duration = roomStats.totalDuration;
        channelStats.txBytes = roomStats.txBytes;
        channelStats.rxBytes = roomStats.rxBytes;
        channelStats.txAudioBytes = roomStats.txAudioBytes;
        channelStats.txVideoBytes = roomStats.txVideoBytes;
        channelStats.rxAudioBytes = roomStats.rxAudioBytes;
        channelStats.rxVideoBytes = roomStats.rxVideoBytes;
        channelStats.txKBitrate = roomStats.txBitrate / 1024;
        channelStats.rxKBitrate = roomStats.rxBitrate / 1024;
        channelStats.txAudioKBitrate = roomStats.txAudioBitrate / 1024;
        channelStats.rxAudioKBitrate = roomStats.rxAudioBitrate / 1024;
        channelStats.txVideoKBitrate = roomStats.txVideoBitrate / 1024;
        channelStats.rxVideoKBitrate = roomStats.rxVideoBitrate / 1024;
        channelStats.lastmileDelay = roomStats.lastmileDelay;
    }
    
    if (deviceStats) {
        channelStats.cpuAppUsage = deviceStats.cpuAppUsage;
        channelStats.cpuTotalUsage = deviceStats.cpuTotalUsage;
        channelStats.memoryTotalUsageRatio = deviceStats.memoryTotalUsage;
        channelStats.memoryAppUsageRatio = deviceStats.memoryAppUsage;
    }
    
    // to do 缺少 txPacketLossRate & rxPacketLossRate & userCount & gatewayRtt
    return channelStats;
}

+ (ThunderPublishVideoMode)transformAgoraVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration*)config {
    CGSize videoSize;
    if (config.dimensions.width < config.dimensions.height) {
        videoSize = config.dimensions;
    } else {
        videoSize = CGSizeMake(config.dimensions.height, config.dimensions.width);
    }
    if (videoSize.width <= 368) {
        return THUNDERPUBLISH_VIDEO_MODE_HIGHQULITY;
    }
    if (videoSize.width <= 544) {
        return THUNDERPUBLISH_VIDEO_MODE_SUPERQULITY;
    }
    if (videoSize.width <= 720) {
        return THUNDERPUBLISH_VIDEO_MODE_BLUERAY_2M;
    }
    if (videoSize.width <= 1280) {
        return THUNDERPUBLISH_VIDEO_MODE_BLUERAY_4M;
    }
    
    if (config.bitrate < 4500) {
        return THUNDERPUBLISH_VIDEO_MODE_BLUERAY_6M;
    }
    if (config.bitrate > 6000) {
        return THUNDERPUBLISH_VIDEO_MODE_BLUERAY_8M;
    }
    
    return THUNDERPUBLISH_VIDEO_MODE_DEFAULT;
}

+ (ThunderVideoCaptureOrientation)transformAgoraVideoOutputOrientationMode:(AgoraVideoOutputOrientationMode)mode {
    switch (mode) {
        case AgoraVideoOutputOrientationModeFixedLandscape:
            return THUNDER_VIDEO_CAPTURE_ORIENTATION_LANDSCAPE;
        case AgoraVideoOutputOrientationModeFixedPortrait:
            return THUNDER_VIDEO_CAPTURE_ORIENTATION_PORTRAIT;
        default:
            return THUNDER_VIDEO_CAPTURE_ORIENTATION_PORTRAIT;
    }
}

+ (float)transformPitch:(double)pitch {
    float thunderPitch;
    thunderPitch = pitch - 1;
    if (thunderPitch > 0) {
        thunderPitch *= 12;
    } else {
        thunderPitch *= 8;
    }
    
    return thunderPitch;
}

@end
