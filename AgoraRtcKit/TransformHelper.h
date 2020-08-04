//
//  TransformHelper.h
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/16.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AgoraConstants.h"
#import "AgoraObjects.h"
#import "AgoraMediaIO.h"
#import "AgoraMediaMetadata.h"
#import "ThunderEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TransformHelper : NSObject

+ (ThunderVideoCanvas *)transformAgoraVideoCanvas:(AgoraRtcVideoCanvas * _Nullable)canvas;

+ (ThunderVideoRenderMode)transformAgoraVideoRenderMode:(AgoraVideoRenderMode)renderMode;

+ (ThunderVideoMirrorMode)transformAgoraMirrorMode:(AgoraVideoMirrorMode)mirrorMode;

+ (ThunderRtcScenarioMode)transformAgoraAudioScenario: (AgoraAudioScenario)scenario;

+ (ThunderRtcAudioConfig)transformAgoraAudioProfile:(AgoraAudioProfile)profile;

+ (ThunderRtcRoomConfig)transformAgoraChannelProfile:(AgoraChannelProfile)profile;

+ (ThunderConnectionStatus)transformAgoraConnectionStateType:(AgoraConnectionStateType)state;

+ (AgoraConnectionStateType)transformThunderConnectionState:(ThunderConnectionStatus)state;

+ (ThunderRtcSoundEffectMode)transformAgoraAudioReverbPreset:(AgoraAudioReverbPreset)reverbPreset;

+ (LiveTranscoding*)transformAgoraLiveTranscoding:(AgoraLiveTranscoding*)transcoding;

+ (ThunderRtcLogLevel)transformAgoraLogFilter:(AgoraLogFilter)filter;

+ (AgoraChannelStats*)transformThunderRtcRoomStats:(ThunderRtcRoomStats*)stats;

+ (AgoraRtcLocalAudioStats*)transformThunderRtcLocalAudioStats:(ThunderRtcLocalAudioStats*)stats;

// to do
+ (AgoraAudioLocalState)transformThunderLocalAudioStreamStatus:(ThunderLocalAudioStreamStatus)status;

+ (AgoraAudioLocalError)transformThunderLocalAudioStreamErrorReason:(ThunderLocalAudioStreamErrorReason)error;

+ (AgoraRtcLocalVideoStats*)transformThunderRtcLocalVideoStats:(ThunderRtcLocalVideoStats*)stats;

+ (AgoraLocalVideoStreamState)transformThunderLocalVideoStreamStatus:(ThunderLocalVideoStreamStatus)status;

+ (AgoraLocalVideoStreamError)transformThunderLocalVideoStreamErrorReason:(ThunderLocalVideoStreamErrorReason)error;

+ (AgoraNetworkQuality)transformThunderLiveRtcNetworkQuality:(ThunderLiveRtcNetworkQuality)quality;

+ (AgoraNetworkType)transformThunderNetworkType:(ThunderNetworkType)type;

+ (NSArray<AgoraRtcAudioVolumeInfo *> *)transformThunderSpeakersInfo:(NSArray<ThunderRtcAudioVolumeInfo *> *)speakers;

+ (AgoraErrorCode)transformThunderPublishCDNErrorCode:(ThunderPublishCDNErrorCode)errorCode;

+ (AgoraAudioRemoteState)transformThunderRemoteAudioState:(ThunderRemoteAudioState)state;

+ (AgoraAudioRemoteStateReason)transformThunderRemoteAudioReason:(ThunderRemoteAudioReason)reason;

+ (AgoraRtcRemoteAudioStats*)transformThunderRtcRemoteAudioStats:(ThunderRtcRemoteAudioStats*)stats withUid:(NSInteger)uid;

+ (AgoraVideoRemoteState)transformThunderRemoteVideoState:(ThunderRemoteVideoState)stats;

+ (AgoraVideoRemoteStateReason)transformThunderRemoteVideoReason:(ThunderRemoteVideoReason)reason;

+ (AgoraRtcRemoteVideoStats*)transformThunderRtcRemoteVideoStats:(ThunderRtcRemoteVideoStats*)stats withUid:(NSInteger)uid;

+ (AgoraUserOfflineReason)transformThunderLiveRtcUserOfflineReason:(ThunderLiveRtcUserOfflineReason)reason;

+ (AgoraChannelStats*)paddingChannelStats:(RoomStats* _Nullable)roomStats deviceStats:(ThunderRtcLocalDeviceStats* _Nullable)deviceStats;

+ (ThunderPublishVideoMode)transformAgoraVideoEncoderConfiguration:(AgoraVideoEncoderConfiguration*)config;

+ (ThunderVideoCaptureOrientation)transformAgoraVideoOutputOrientationMode:(AgoraVideoOutputOrientationMode)mode;

+ (float)transformPitch:(double)pitch;

@end

NS_ASSUME_NONNULL_END
