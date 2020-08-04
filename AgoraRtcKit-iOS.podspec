Pod::Spec.new do |s|
        s.name         = 'AgoraRtcKit-iOS'
        s.version      = '1.0.0'
        s.summary      = 'Warp Thunder SDK to AgoraRtcKit type'
        s.license      = { :type => 'MIT', :file => 'LICENSE' }
        s.description      = 'This CocoaPods provides the ability to use a UILabel that may be started and stopped blinking.'
        
        s.homepage         = 'https://github.com/dubian0608/BlinkLabel'
        s.license          = { :type => 'MIT', :file => 'LICENSE' }
        s.author           = { 'dubian0608' => 'zhangji2@yy.com' }
        s.source       = { :git => 'https://github.com/dubian0608/AgoraRtcKit-iOS.git', :tag => s.version.to_s }
        s.ios.deployment_target = '8.0'
        #s.dependency 'thunder', '2.9.12'
        s.source_files = 'AgoraRtcKit/**'
end

