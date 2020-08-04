//
//  CustomVideoSource.m
//  AgoraRtcKit
//
//  Created by 张骥 on 2020/7/20.
//  Copyright © 2020 ZhangJi. All rights reserved.
//

#import "CustomVideoSource.h"

@interface CustomVideoSource()

@property(nonatomic, strong) id<ThunderVideoFrameConsumer> thunderConsumer;

@end


@implementation CustomVideoSource

- (ThunderVideoBufferType)bufferType {
    return (ThunderVideoBufferType)[_agoraVideoSource bufferType];
}

- (void)onDispose {
    [_agoraVideoSource shouldDispose];
}

- (BOOL)onInitialize:(nullable id<ThunderVideoFrameConsumer>)protocol {
    self.thunderConsumer = protocol;
    return [_agoraVideoSource shouldInitialize];
}

- (void)onStart {
    [_agoraVideoSource shouldStart];
}

- (void)onStop {
    [_agoraVideoSource shouldStop];
}

- (void)consumePixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer withTimestamp:(CMTime)timestamp rotation:(AgoraVideoRotation)rotation {
    [self.thunderConsumer consumePixelBuffer:pixelBuffer withTimestamp:timestamp rotation:(ThunderVideoRotation)rotation];
}

- (void)consumeRawData:(void * _Nonnull)rawData withTimestamp:(CMTime)timestamp format:(AgoraVideoPixelFormat)format size:(CGSize)size rotation:(AgoraVideoRotation)rotation {
    [self.thunderConsumer consumeRawData:rawData withTimestamp:timestamp format:(ThunderVideoPixelFormat)format size:size rotation:(ThunderVideoRotation)rotation];
}

@end

@interface CustomExternalVideoSource()

@property(nonatomic, assign) BOOL pushMode;
@property(nonatomic, assign) BOOL useTexture;

@property(nonatomic, strong) id<ThunderVideoFrameConsumer> thunderConsumer;

@end

@implementation CustomExternalVideoSource

- (instancetype)initWithUseTexture:(BOOL)useTexture pushMode:(BOOL)pushMode {
    if (self = [super init]) {
        self.pushMode = pushMode;
        self.useTexture = useTexture;
    }
    return self;
}



- (ThunderVideoBufferType)bufferType {
    if (self.useTexture) {
        return THUNDER_VIDEOBUFFER_TYPE_PIXELBUFFER;
    } else {
        return THUNDER_VIDEOBUFFER_TYPE_RAWDATA;
    }
}

- (void)onDispose {
    
}

- (BOOL)onInitialize:(nullable id<ThunderVideoFrameConsumer>)protocol {
    _thunderConsumer = protocol;
    return true;
}

- (void)onStart {
    
}

- (void)onStop {
    
}

- (BOOL)pushExternalVideoFrame:(AgoraVideoFrame * _Nonnull)frame {
    if (!_pushMode) { return false;}
    
    if (self.useTexture) {
        [_thunderConsumer consumePixelBuffer:frame.textureBuf withTimestamp:frame.time rotation:frame.rotation];
    } else {
        if (frame.format > 3) { return false; }
        [_thunderConsumer consumeRawData:(__bridge void * _Nonnull)(frame.dataBuf) withTimestamp:frame.time format:(ThunderVideoPixelFormat)(frame.format - 1) size:CGSizeMake(frame.strideInPixels, frame.height) rotation:frame.rotation];
    }
    return true;
}

@end
