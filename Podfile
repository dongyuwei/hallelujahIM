platform :osx, '10.9'

use_frameworks!

target 'hallelujah' do
    pod "GCDWebServer", "~> 3.0"
    pod 'MDCDamerauLevenshtein', :git => 'https://github.com/modocache/MDCDamerauLevenshtein.git', :branch => 'master'
end

target 'Tests' do
  pod "GCDWebServer", "~> 3.0"
  pod 'MDCDamerauLevenshtein', :git => 'https://github.com/modocache/MDCDamerauLevenshtein.git', :branch => 'master'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = 'RECOMMENDED_MACOSX_DEPLOYMENT_TARGET'
         end
    end
  end
end