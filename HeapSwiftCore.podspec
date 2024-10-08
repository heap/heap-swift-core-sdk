Pod::Spec.new do |s|
  s.name = 'HeapSwiftCore'
  s.version = '0.7.2'
  s.license = { :type => 'MIT' }
  s.summary = 'The core Heap library used for apps on Apple platforms.'
  s.homepage = 'https://heap.io'
  s.author = 'Heap Inc.'
  s.source = { :git => 'https://github.com/heap/heap-swift-core-sdk.git', :tag => s.version }
  
  s.requires_arc = true
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.tvos.deployment_target = '12.0'
  # s.watchos.deployment_target = '5.0'
  
  s.cocoapods_version = '>= 1.7.0'
  
  s.source_files = 'Development/Sources/HeapSwiftCore/**/*.swift'
  
  s.dependency 'SwiftProtobuf', '~> 1.6'
  s.dependency 'HeapSwiftCoreInterfaces', '0.6.1'
  
  s.swift_versions = ['5.0']
end
