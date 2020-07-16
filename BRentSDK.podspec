Pod::Spec.new do |s|
  s.name = 'BRentSDK'
  s.version = '0.1.2'
  s.author = 'BRent Inc'
  s.license = { :type => 'Proprietary', :text => 'Copyright 2020 BRent Inc. All rights reserved.' }
  s.homepage = 'https://github.com/barrigaz/BRentSDK-iOS'
  s.summary = 'BRent iOS SDK'
  s.description      = <<-DESC
Assistant for managing ads and trackers
                       DESC
  
  s.source = { 
	:git => "https://github.com/barrigaz/BRentSDK-iOS.git", 
	:tag => "#{s.version}"
  }
  s.vendored_frameworks = 'BRentSDK.xcframework'
  s.platform =:ios, '12.0'
end