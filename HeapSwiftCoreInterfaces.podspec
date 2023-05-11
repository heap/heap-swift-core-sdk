Pod::Spec.new do |s|
  s.name = 'HeapSwiftCoreInterfaces'
  s.version = '0.1.1'
  s.license = { :type => 'MIT' }
  s.summary = 'ABI stable interface package for HeapSwiftCore.'
  s.homepage = 'https://heap.io'
  s.author = 'Heap Inc.'
  s.source = { :http => "https://cdn.heapanalytics.com/ios/heap-swift-core-interfaces-#{s.version}.zip", :type => 'zip' }
  
  s.requires_arc = true
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.tvos.deployment_target = '12.0'
  # s.watchos.deployment_target = '5.0'
  
  s.cocoapods_version = '>= 1.7.0'
  
  s.vendored_frameworks = 'HeapSwiftCoreInterfaces.xcframework'
  
  s.swift_versions = ['5.0']
end
