# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'

# ignore all warnings from all pods
inhibit_all_warnings!

def sharedPods
  pod 'BitmarkSDK', git: 'https://github.com/bitmark-inc/bitmark-sdk-swift.git', branch: 'master'
  pod 'KeychainAccess'
  pod 'SnapKit', '~> 5.0.0'
  pod 'SwifterSwift'
  pod 'PanModal'
  pod 'Alamofire'
  pod 'IQKeyboardManagerSwift'
  pod 'NotificationBannerSwift'
  pod 'RealmSwift'
  pod 'BEMCheckBox'

  # ReactiveX
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'RxFlow'
  pod 'RxAlamofire'
  pod 'RxOptional'
  
  # error reporting
  pod 'Sentry'
  
  # custom logger
  pod 'XCGLogger', '~> 7.0.0'
end

target 'Bitmark' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Bitmark
  sharedPods
end

target 'Bitmark Dev' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for Bitmark
  sharedPods
end
