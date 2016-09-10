Pod::Spec.new do |s|
  s.name             = "ExpressiveFoundation"
  s.version          = "0.1.0"
  s.summary          = "Handles GCD, observation and other foundation-level concepts"

  s.description      = <<-DESC
  Swift nanoframework for writing concise and expressive code involving GCD, observation and other foundation-level concepts.
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/ExpressiveFoundation.swift"
  s.source           = { :git => "https://github.com/andreyvit/ExpressiveFoundation.swift.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source_files = 'Source/**/*.{h,m,swift}'
end
