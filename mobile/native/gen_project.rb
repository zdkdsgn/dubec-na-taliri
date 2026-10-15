require 'fileutils'
require 'xcodeproj'

root = File.expand_path(__dir__)
build_number = (File.read(File.join(root, 'BUILD_NUMBER')).strip rescue '1')
proj_path = File.join(root, 'SkolaNaTaliri.xcodeproj')
FileUtils.rm_rf(proj_path)
project = Xcodeproj::Project.new(proj_path)

ios = project.new_target(:application, 'SkolaNaTaliri', :ios, '26.0')

shared = project.main_group.new_group('Shared', 'Shared')
app    = project.main_group.new_group('SkolaNaTaliri', 'SkolaNaTaliri')

Dir.glob(File.join(root, 'Shared', '*.swift')).sort.each do |f|
  ios.add_file_references([shared.new_file(File.basename(f))])
end
Dir.glob(File.join(root, 'SkolaNaTaliri', '*.swift')).sort.each do |f|
  ios.add_file_references([app.new_file(File.basename(f))])
end
assets = app.new_file('Assets.xcassets')
ios.resources_build_phase.add_file_reference(assets)

ios.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'cz.zdkdsgn.skolanatalire'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['INFOPLIST_KEY_CFBundleDisplayName'] = 'Škola na talíři'
  s['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  s['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  s['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
  s['INFOPLIST_KEY_ITSAppUsesNonExemptEncryption'] = 'NO'
  s['INFOPLIST_KEY_LSApplicationCategoryType'] = 'public.app-category.education'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '26.0'
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = build_number
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['CODE_SIGN_ENTITLEMENTS'] = 'SkolaNaTaliri/SkolaNaTaliri.entitlements'
  s['DEVELOPMENT_TEAM'] = 'WV966K9T8M'
  s['ENABLE_PREVIEWS'] = 'YES'
end

# ── watchOS appka vestavěná do iPhone appky ──
watch = project.new_target(:application, 'SkolaNaTaliriWatch', :watchos, '10.0')
wgroup = project.main_group.new_group('Watch', 'Watch')
Dir.glob(File.join(root, 'Watch', '*.swift')).sort.each do |f|
  watch.add_file_references([wgroup.new_file(File.basename(f))])
end
Dir.glob(File.join(root, 'Shared', '*.swift')).sort.each do |f|
  ref = shared.files.find { |x| x.path == File.basename(f) }
  watch.add_file_references([ref])
end
wassets = wgroup.new_file('Assets.xcassets')
watch.resources_build_phase.add_file_reference(wassets)

watch.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'cz.zdkdsgn.skolanatalire.watchkitapp'
  s['PRODUCT_NAME'] = 'SkolaNaTaliriWatch'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['INFOPLIST_KEY_CFBundleDisplayName'] = 'Škola na talíři'
  s['INFOPLIST_KEY_WKApplication'] = 'YES'
  s['INFOPLIST_KEY_WKCompanionAppBundleIdentifier'] = 'cz.zdkdsgn.skolanatalire'
  s['INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp'] = 'YES'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['SWIFT_VERSION'] = '5.0'
  s['SDKROOT'] = 'watchos'
  s['SUPPORTED_PLATFORMS'] = 'watchsimulator watchos'
  s['TARGETED_DEVICE_FAMILY'] = '4'
  s['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = build_number
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['CODE_SIGN_ENTITLEMENTS'] = 'App.entitlements'
  s['DEVELOPMENT_TEAM'] = 'WV966K9T8M'
  s['ENABLE_PREVIEWS'] = 'YES'
end

ios.add_dependency(watch)
embed = ios.new_copy_files_build_phase('Embed Watch Content')
embed.dst_subfolder_spec = '16'
embed.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
bf = embed.add_file_reference(watch.product_reference, true)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }


# ── widgety (iOS widget + watchOS complication) ──
wdgroup = project.main_group.new_group('Widget', 'Widget')
widget_src = wdgroup.new_file('SkolaWidget.swift')
wdgroup.new_file('Info.plist')

def add_widget(project, name, bundle, platform, deploy, shared, widget_src, build_number)
  t = project.new_target(:app_extension, name, platform, deploy)
  t.add_file_references([widget_src])
  %w[Models.swift DataService.swift SharedStore.swift DaySummary.swift].each do |f|
    ref = shared.files.find { |x| x.path == f }
    t.add_file_references([ref])
  end
  t.build_configurations.each do |c|
    s = c.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = bundle
    s['PRODUCT_NAME'] = name
    s['GENERATE_INFOPLIST_FILE'] = 'YES'
    s['INFOPLIST_FILE'] = 'Widget/Info.plist'
    s['INFOPLIST_KEY_CFBundleDisplayName'] = 'Škola na talíři'
    s['SKIP_INSTALL'] = 'YES'
    s['SWIFT_VERSION'] = '5.0'
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['DEVELOPMENT_TEAM'] = 'WV966K9T8M'
    s['CODE_SIGN_ENTITLEMENTS'] = 'App.entitlements'
    s['MARKETING_VERSION'] = '1.0'
    s['CURRENT_PROJECT_VERSION'] = build_number
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
    if platform == :watchos
      s['SDKROOT'] = 'watchos'
      s['SUPPORTED_PLATFORMS'] = 'watchsimulator watchos'
      s['TARGETED_DEVICE_FAMILY'] = '4'
      s['WATCHOS_DEPLOYMENT_TARGET'] = deploy
    else
      s['TARGETED_DEVICE_FAMILY'] = '1'
      s['IPHONEOS_DEPLOYMENT_TARGET'] = deploy
    end
  end
  t
end

def embed_extension(host, ext)
  host.add_dependency(ext)
  phase = host.new_copy_files_build_phase('Embed Foundation Extensions')
  phase.dst_subfolder_spec = '13'
  bf = phase.add_file_reference(ext.product_reference, true)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

ios_widget   = add_widget(project, 'SkolaWidget', 'cz.zdkdsgn.skolanatalire.widget', :ios, '26.0', shared, widget_src, build_number)
watch_widget = add_widget(project, 'SkolaWatchWidget', 'cz.zdkdsgn.skolanatalire.watchkitapp.widget', :watchos, '10.0', shared, widget_src, build_number)
embed_extension(ios, ios_widget)
embed_extension(watch, watch_widget)

project.save
puts "Saved #{proj_path}"
