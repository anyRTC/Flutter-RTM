#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ar_rtm.podspec' to validate before publishing.
#

require "yaml"
require "ostruct"
project = OpenStruct.new YAML.load_file("../pubspec.yaml")

Pod::Spec.new do |s|
  s.name             = project.name
  s.version          = project.version
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/anyRTC/Flutter-RTM'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'anyRTC' => 'yangjihua@dync.cc' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'ARtmKit_iOS', '1.0.1.1'
  s.platform = :ios, '9.0'

end
