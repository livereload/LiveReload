Pod::Spec.new do |s|
  s.name             = "ExpressiveCollections"
  s.version          = "0.1.0"
  s.summary          = "Swift nanoframework for writing concise and expressive code involving standard Swift collections."

  s.description      = <<-DESC
                       DESC

  s.license          = 'MIT'
  s.author           = { "Andrey Tarantsov" => "andrey@tarantsov.com" }
  s.homepage         = "https://github.com/andreyvit/ExpressiveCollections.swift"
  s.source           = { :git => "https://github.com/andreyvit/ExpressiveCollections.swift.git",
                         :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"

  s.source_files = 'Source/**/*.{swift}'
end
