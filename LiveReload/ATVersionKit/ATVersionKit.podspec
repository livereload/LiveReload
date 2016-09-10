Pod::Spec.new do |s|
  s.name             = "ATVersionKit"
  s.version          = "0.5.0"
  s.summary          = "Generic and semantic version numbers"

  s.description      = <<-DESC
    Cocoa library for parsing and processing version numbers.
  DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/ATVersionKit"
  s.source           = { :git => "https://github.com/andreyvit/ATVersionKit.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"

  s.source_files = 'Source/**/*.{h,m,swift}'
end
