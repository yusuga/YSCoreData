Pod::Spec.new do |s|
  s.name = 'YSCoreData'
  s.version = '0.4.0'
  s.summary = 'Multi-Context CoreData'
  s.homepage = 'https://github.com/yusuga/YSCoreData'
  s.license = 'MIT'
  s.author = 'Yu Sugawara'
  s.source = { :git => 'https://github.com/yusuga/YSCoreData.git', :tag => s.version.to_s }
  s.platform = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.source_files = 'Classes/YSCoreData/*.{h,m}'
  s.requires_arc = true
  
  s.compiler_flags = '-fmodules'
end