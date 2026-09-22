require 'xcodeproj'

root = File.expand_path('SkolaNaTaliriWatch', __dir__)
proj_path = File.join(root, 'SkolaNaTaliriWatch.xcodeproj')

project = Xcodeproj::Project.new(proj_path)

target = project.new_target(:application, 'SkolaNaTaliriWatch', :watchos, '10.0')

group = project.main_group.new_group('SkolaNaTaliriWatch', 'SkolaNaTaliriWatch')
%w[SkolaNaTaliriWatchApp.swift ContentView.swift Model.swift SkolaVyberView.swift].each do |fname|
  fref = group.new_file(fname)
  target.add_file_references([fref])
end

common_settings = {
  'PRODUCT_BUNDLE_IDENTIFIER' => 'cz.zdkdsgn.skolanatalire.watch',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_WKApplication' => 'YES',
  'INFOPLIST_KEY_WKWatchOnly' => 'YES',
  'INFOPLIST_KEY_UISupportedInterfaceOrientations' => 'UIInterfaceOrientationPortrait',
  'INFOPLIST_KEY_CFBundleDisplayName' => 'Škola na talíři',
  'SWIFT_VERSION' => '5.0',
  'TARGETED_DEVICE_FAMILY' => '4',
  'SDKROOT' => 'watchos',
  'SUPPORTED_PLATFORMS' => 'watchsimulator watchos',
  'WATCHOS_DEPLOYMENT_TARGET' => '10.0',
  'CODE_SIGN_STYLE' => 'Automatic',
  'CODE_SIGN_IDENTITY' => '-',
  'ENABLE_PREVIEWS' => 'YES',
  'ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS' => 'NO',
}

target.build_configurations.each do |config|
  common_settings.each { |k, v| config.build_settings[k] = v }
end

project.build_configurations.each do |config|
  config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
end

project.save
puts "Saved #{proj_path}"
