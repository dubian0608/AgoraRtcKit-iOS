//
//  AgoraConstants.m
//  AgoraConstants
//
//  Created by 张骥 on 2020/7/16.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import "AgoraConstants.h"

__attribute__((visibility("default"))) NSInteger const AgoraVideoBitrateStandard = 0;

__attribute__((visibility("default"))) NSInteger const AgoraVideoBitrateCompatible = -1;

__attribute__((visibility("default"))) NSInteger const AgoraVideoBitrateDefaultMin = -1;

__attribute__((visibility("default"))) CGSize const AgoraVideoDimension120x120 = CGSizeMake(120, 120);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension160x120 = CGSizeMake(160, 120);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension180x180 = CGSizeMake(180, 180);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension240x180 = CGSizeMake(240, 180);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension320x180 = CGSizeMake(320, 180);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension240x240 = CGSizeMake(240, 240);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension320x240 = CGSizeMake(320, 240);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension424x240 = CGSizeMake(424, 240);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension360x360 = CGSizeMake(360, 360);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension480x360 = CGSizeMake(480, 360);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension640x360 = CGSizeMake(640, 360);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension480x480 = CGSizeMake(480, 480);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension640x480 = CGSizeMake(640, 480);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension840x480 = CGSizeMake(840, 480);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension960x720 = CGSizeMake(960, 720);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension1280x720 = CGSizeMake(1280, 720);
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension1920x1080 = CGSizeMake(1920, 1080);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension2540x1440 = CGSizeMake(2540, 1440);
__attribute__((visibility("default"))) CGSize const AgoraVideoDimension3840x2160 = CGSizeMake(3840, 2160);
#endif
