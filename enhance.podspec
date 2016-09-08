#
# Be sure to run `pod lib lint enhance.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "enhance"
  s.version          = "0.4.0"
  s.summary          = "A simple image viewer with zooming and UIDynamics for maximum fun"
  s.description      = <<-DESC
                       * Got some images?
                       * This shows them in a pinch-zoomable view inside of the view controller of your choice
                       * Fancy UIDynamics lets you swipe them out of the way or ease it back in place
                       * Simple, direct, not trying to do everything under the sun
                       DESC
  s.homepage         = "https://github.com/amco/enhance"
  s.screenshots     = "http://i.imgur.com/mfQxIyN.jpg", "http://i.imgur.com/vlpMYFj.png", "http://i.imgur.com/98J3wNl.jpg", "http://i.imgur.com/r7RgeGP.jpg"
  s.license          = 'MIT'
  s.author           = { "Adam Yanalunas" => "adamy@amcoonline.net" }
  s.source           = { :git => "https://github.com/amco/enhance.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/adamyanalunas'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  s.subspec 'Localization' do |t|
    %w|en|.map {|localename|
      t.subspec localename do |u|
        u.ios.resources = "Pod/Localization/#{localename}.lproj"
        u.ios.preserve_paths = "Pod/Localization/#{localename}.lproj"
     end
    }
  end

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Accelerate', 'QuartzCore', 'AssetsLibrary'
  # s.dependency 'AFNetworking', '~> 2.3'
end
