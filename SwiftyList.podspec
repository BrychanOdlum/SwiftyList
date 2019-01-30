#  Be sure to run `pod spec lint SwiftyList.podspec' to ensure this is a
Pod::Spec.new do |s|
  s.name         = "SwiftyList"
  s.version      = "0.0.1"
  s.summary      = "An infinite and virtualized list for macOS written in Swift."

  s.homepage     = "https://github.com/BrychanOdlum/SwiftyList"
  s.license      = "LGPL"

  s.author             = { "Brychan Bennett-Odlum" => "git@brychan.io" }
  s.social_media_url   = "http://github.com/BrychanOdlum"

  s.platform     = :osx, "10.14"


  s.source       = { :git => "https://github.com/BrychanOdlum/SwiftyList.git", :tag => "#{s.version}" }
  
  s.framework = "Cocoa"
  
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.source_files = "SwiftyList/**/*.{swift}"

  s.swift_version = "4.2"

end
