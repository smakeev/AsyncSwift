Pod::Spec.new do |s|
  s.name = 'SomeAsyncSwift'
  s.version = '0.2.1'
  s.license = 'MIT'
  s.summary = 'Async operations via Async Await and more'
  s.homepage = 'https://github.com/smakeev/AsyncSwift'
  s.authors = { 'Sergey Makeev' => 'makeev.87@gmaol.com' }
  s.source = { :git => 'https://github.com/smakeev/AsyncSwift.git', :tag => s.version }
  s.documentation_url = 'https://github.com/smakeev/AsyncSwift/wiki'

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '3.0'

  s.swift_versions = ['5.0', '5.1']

  s.source_files = 'Source/*.swift'
end
