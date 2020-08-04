//
//  CustomVideoSource.h
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/20.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AgoraMediaIO.h"
#import "ThunderEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomVideoSource : NSObject<ThunderCustomVideoSourceProtocol, AgoraVideoFrameConsumer>

@property (nonatomic, weak) id<AgoraVideoSourceProtocol> agoraVideoSource;

@end

@interface CustomExternalVideoSource : NSObject<ThunderCustomVideoSourceProtocol>

- (instancetype)initWithUseTexture:(BOOL)useTexture pushMode:(BOOL)pushMode;

- (BOOL)pushExternalVideoFrame:(AgoraVideoFrame * _Nonnull)frame;

@end

NS_ASSUME_NONNULL_END
