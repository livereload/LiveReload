Pod::Spec.new do |s|
  s.name             = "ATPathSpec"
  s.version          = "1.2.0"
  s.summary          = "Path matching library with a configurable syntax (shell glob, gitignore & custom)"

  s.description      = <<-DESC
    Path matching library with a flexible configurable syntax, every syntax feature can be enabled/disabled with a flag. Predefined flavours for shell globs and gitignore patterns.
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/ATPathSpec"
  s.source           = { :git => "https://github.com/andreyvit/ATPathSpec.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"

  s.source_files = 'Source/**/*.{h,m,swift}'
  s.private_header_files = 'Source/*Private.h'
end
