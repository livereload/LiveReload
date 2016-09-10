Pod::Spec.new do |s|
  s.name             = "ExpressiveCasting"
  s.version          = "0.6.0"
  s.summary          = "Handles untyped and potentially untrusted incoming data (JSON APIs, User Defaults and such)"

  s.description      = <<-DESC
  Swift nanoframework for writing concise and expressive code when processing untyped and potentially untrusted incoming data (JSON APIs, User Defaults and such).
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/ExpressiveSwift/ExpressiveCasting"
  s.source           = { :git => "https://github.com/ExpressiveSwift/ExpressiveCasting.git",
                         :tag => "#{s.version.to_s}" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source_files = 'Sources/*.swift'
end
