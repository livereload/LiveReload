Pod::Spec.new do |s|
  s.name             = "FSMonitoringKit"
  s.version          = "1.0.0"
  s.summary          = "FSEvents-based file system monitoring with guaranteed fine-grained change events"

  s.description      = <<-DESC
    Flexible Cocoa file system monitoring library with guaranteed fine-grained change events (based on FSEvents)
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/FSMonitoringKit"
  s.source           = { :git => "https://github.com/andreyvit/FSMonitoringKit.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"

  s.source_files = 'Source/**/*.{h,m,swift}', 'FSEventsFix/*.{h,m}'
end
