Pod::Spec.new do |s|
  s.name        = "Paddle-MAS"
  s.version     = "1.0"
  s.summary     = "A licensing framework for OS X"
  s.description = "Paddle is an easy to use framework for OS X including analytics features."
  s.homepage    = "https://www.paddle.com"
  s.license     = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.authors     = {
    'Louis Harwood' => 'louis@paddle.com',
    'Christian Owens' => 'christian@paddle.com',
  }

  s.platform = :osx, '10.7'
  s.source   = { :http => "https://github.com/PaddleHQ/Paddle-MAS/archive/v1.0.tar.gz" }

  s.public_header_files = 'Paddle.framework/Headers/*.h'
  s.vendored_framework  = 'Paddle.framework'
  s.resources           = 'Paddle.framework'
  s.xcconfig            = { 'FRAMEWORK_SEARCH_PATHS' => '"${PODS_ROOT}/Paddle"' }
  s.requires_arc        = false
end
