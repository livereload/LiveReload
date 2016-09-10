Pod::Spec.new do |s|
  s.name             = "ExpressiveCocoa"
  s.version          = "0.1.0"
  s.summary          = "Swift nanoframework for OS X-specific Cocoa-level APIs"

  s.description      = <<-DESC
  Swift nanoframework for writing concise and expressive code dealing with OS X-specific Cocoa-level APIs.
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/ExpressiveCocoa.swift"
  s.source           = { :git => "https://github.com/andreyvit/ExpressiveCocoa.swift.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source_files = 'Source/**/*.{h,m,swift}'
end
