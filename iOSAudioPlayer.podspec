Pod::Spec.new do |s|
  s.name             = 'iOSAudioPlayer'
  s.version          = '0.1.15'
  s.summary          = 'iOSAudioPlayer is a Swift based iOS module that provides player control features.'
  s.description      = 'iOSAudioPlayer is a Swift based iOS module that provides player control features. This module represents a wrapper over AVPlayer. It is available starting with iOS 8.'
  s.homepage         = 'https://github.com/3pillarlabs/ios-audio-player.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '3Pillar Global' => 'ios.support@3pillarglobal.com' }
  s.source           = { :git => 'https://github.com/3pillarlabs/ios-audio-player.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'iOSAudioPlayer/**/*'
  s.public_header_files = 'iOSAudioPlayer/**/*.h'
end
