# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def sharedPods
  pod 'BitmarkSDK', git: 'https://github.com/bitmark-inc/bitmark-sdk-swift.git', branch: 'master'
  pod 'KeychainAccess'
  pod 'SnapKit', '~> 5.0.0'
  pod 'SwifterSwift'
  pod 'PanModal'
end

target 'BitmarkRegistry' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for BitmarkRegistry
  sharedPods
end

target 'BitmarkRegistry Dev' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # Pods for BitmarkRegistry
  sharedPods
end
