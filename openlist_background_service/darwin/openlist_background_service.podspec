#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint openlist_background_service.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'openlist_background_service'
  s.version          = '0.0.1'
  s.summary          = 'For OpenListApp mobile APP background service'
  s.description      = <<-DESC
For OpenListApp mobile APP background service
                       DESC
  s.homepage         = 'https://github.com/OpenListApp'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OpenListApp' => 'yu@iotserv.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

#   s.dependency 'OpenListMobile' , '0.0.2'
#   s.dependency 'AListMobile' , '~> 0.0.3'
#   s.dependency 'AListMobile'
  s.preserve_paths = 'OpenListMobile.xcframework/**/*'
  s.xcconfig =  {'OTHER_LDFLAGS' => '-framework OpenListMobile','ENABLE_BITCODE' => 'NO'}
  s.vendored_frameworks = 'OpenListMobile.xcframework'
  s.libraries = "resolv.9", "resolv"

  s.static_framework = true
end
