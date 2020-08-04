//
//  AgoraObjects.m
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/16.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import "AgoraObjects.h"

@implementation AgoraUserInfo

@end

@implementation AgoraChannelStats

@end

@implementation AgoraRtcLocalAudioStats

@end

@implementation AgoraVideoEncoderConfiguration

- (instancetype _Nonnull)initWithSize:(CGSize)size
                            frameRate:(AgoraVideoFrameRate)frameRate
                              bitrate:(NSInteger)bitrate
                      orientationMode:(AgoraVideoOutputOrientationMode)orientationMode {
    if (self = [super init]) {
        self.dimensions = size;
        self.frameRate = frameRate;
        self.bitrate = bitrate;
        self.orientationMode = orientationMode;
    }
    return self;
}


- (instancetype _Nonnull)initWithWidth:(NSInteger)width
                                height:(NSInteger)height
                             frameRate:(AgoraVideoFrameRate)frameRate
                               bitrate:(NSInteger)bitrate
                       orientationMode:(AgoraVideoOutputOrientationMode)orientationMode {
    if (self = [super init]) {
        self = [self initWithSize:CGSizeMake(width, height)
                        frameRate:frameRate
                          bitrate:bitrate
                  orientationMode:orientationMode];
    }
    return self;
}

@end

@implementation AgoraRtcVideoCanvas

@end

@implementation AgoraBeautyOptions


@end

@implementation AgoraRtcRemoteAudioStats

@end

@implementation AgoraRtcRemoteVideoStats

@end

@implementation AgoraRtcLocalVideoStats


@end

@implementation AgoraRtcAudioVolumeInfo


@end

@implementation AgoraVideoFrame


@end

@implementation AgoraLastmileProbeConfig


@end

@implementation AgoraImage


@end

@implementation AgoraLiveInjectStreamConfig


@end

@implementation AgoraLiveTranscoding


@end

@implementation AgoraLiveTranscodingUser


@end

@implementation WatermarkOptions

@end
