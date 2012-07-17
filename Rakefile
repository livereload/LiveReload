#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'rake/clean'

Dir['tasks/*.rb'].each { |file| require file }
Dir['nodeapp/*/tasks/*.rb'].each { |file| require file }

MacVersion = VersionTasks.new('ver:mac', 'app/mac/Info.plist', %w(app/mac/src/app_version.h))

RoutingTasks.new(
  :app_src        => 'LiveReload,Shared',
  :gen_src        => 'Shared/gen_src',
  :messages_json  => 'backend/config/client-messages.json',
  :api_dumper_js  => "backend/bin/livereload-backend-print-apis.js")


ROOT_DIR = File.expand_path('.')
BUILDS_DIR = File.join(ROOT_DIR, 'dist')
# XCODE_RELEASE_DIR = File.expand_path('~/Documents/XBuilds/Release')
XCODE_RELEASE_DIR = File.join(ROOT_DIR, 'LiveReload/build/Release')
TAG_PREFIX = 'v'
S3_BUCKET = 'download.livereload.com'

MAC_BUNDLE_NAME = 'LiveReload.app'
MAC_ZIP_BASE_NAME = "LiveReload"
MAC_SRC = File.join(ROOT_DIR, 'LiveReload')


def find_unused_suffix prefix, separator
  all_tags = `git tag`.strip.split("\n")
  if all_tags.include?("#{TAG_PREFIX}#{prefix}")
    puts "Tag #{TAG_PREFIX}#{prefix} already exists."
    exit
  end
  return prefix
end


namespace :mac do

  desc "Upload the given build to S3"
  task :upload, :suffix do |t, args|
    zip_name = "#{MAC_ZIP_BASE_NAME}-#{args[:suffix]}.zip"
    zip_path_in_builds = File.join(BUILDS_DIR, zip_name)

    sh 's3cmd', '-P', 'put', zip_path_in_builds, "s3://#{S3_BUCKET}/#{zip_name}"
  end

  desc "Tag, build and zip using a custom suffix"
  task :custom, :suffix do |t, args|
    suffix = args[:suffix]
    raise "Suffix is required for mac:custom" if suffix.empty?

    suffix_for_tag = find_unused_suffix(suffix, '-')
    tag = "#{TAG_PREFIX}#{suffix_for_tag}"
    sh 'git', 'tag', tag

    Dir.chdir 'LiveReload/Compilers' do
      sh 'git', 'tag', tag
    end

    zip_name = "#{MAC_ZIP_BASE_NAME}-#{suffix}.zip"
    zip_path = File.join(XCODE_RELEASE_DIR, zip_name)
    zip_path_in_builds = File.join(BUILDS_DIR, zip_name)

    Dir.chdir MAC_SRC do
      sh 'xcodebuild clean'
      sh 'xcodebuild'
    end
    Dir.chdir XCODE_RELEASE_DIR do
      rm_rf zip_name
      sh 'zip', '-9rX', zip_name, MAC_BUNDLE_NAME
    end

    mkdir_p File.dirname(zip_path_in_builds)
    cp zip_path, zip_path_in_builds

    sh 'open', '-R', zip_path_in_builds

    Rake::Task['mac:upload'].invoke(suffix)

    sh 'git', 'tag'

    puts "http://download.livereload.com.s3.amazonaws.com/LiveReload-#{suffix}.zip"
    puts "http://download.livereload.com/LiveReload-#{suffix}.zip"
  end

  desc "Tag using the current version number"
  task :tag do |t, args|
    suffix_for_tag = find_unused_suffix(MacVersion.short_version, '-')
    tag = "#{TAG_PREFIX}#{suffix_for_tag}"
    sh 'git', 'tag', tag

    Dir.chdir 'LiveReload/Compilers' do
      sh 'git', 'tag', tag
    end
  end

  desc "Tag, build and zip using the current version number"
  task :release do |t, args|
    Rake::Task['mac:custom'].invoke(MacVersion.short_version)
  end

  desc "Tag, build and zip using the current version number suffixed with -pre"
  task :prerelease do |t, args|
    suffix = find_unused_suffix("#{MacVersion.short_version}-pre", '')
    Rake::Task['mac:custom'].invoke(suffix)
  end

  desc "Tag, build and zip using the current version number"
  task :dev do |t, args|
    suffix = find_unused_suffix("#{MacVersion.short_version}-dev-#{Time.now.strftime('%b%d').downcase}", '-')
    Rake::Task['mac:custom'].invoke(suffix)
  end

end


file 'LiveReload/livereload.js' => ['js/dist/livereload.js'] do |t|
  cp t.prerequisites.first, t.name
end

file 'extensions/LiveReload.safariextension/livereload.js' => ['js/dist/livereload.js'] do |t|
  cp t.prerequisites.first, t.name
end
file 'extensions/Chrome/LiveReload/livereload.js' => ['js/dist/livereload.js'] do |t|
  cp t.prerequisites.first, t.name
end
file 'extensions/Firefox/content/livereload.js' => ['js/dist/livereload.js'] do |t|
  cp t.prerequisites.first, t.name
end
file 'backend/res/livereload.js' => ['js/dist/livereload.js'] do |t|
  mkdir_p File.dirname(t.name)
  cp t.prerequisites.first, t.name
end

desc "Update LiveReload.js from js/dist/"
task :js => ['LiveReload/livereload.js', 'extensions/LiveReload.safariextension/livereload.js', 'extensions/Chrome/LiveReload/livereload.js', 'extensions/Firefox/content/livereload.js', 'backend/res/livereload.js']

desc "Push all Git changes"
task :push do
  Dir.chdir 'LiveReload/Compilers' do
    sh 'git', 'push'
    sh 'git', 'push', '--tags'
  end
  sh 'git', 'push'
  sh 'git', 'push', '--tags'
end



################################################################################
# Windows

WIN_BUNDLE_DIR = "WinApp"
WIN_BUNDLE_RESOURCES_DIR = "#{WIN_BUNDLE_DIR}/Resources"
WIN_BUNDLE_BACKEND_DIR = "#{WIN_BUNDLE_RESOURCES_DIR}/backend"

WIN_VERSION_FILES = %w(
    Windows/version.h
    Windows/LiveReload.nsi
)

def win_version
    File.read('Windows/VERSION').strip
end

namespace :win do

  desc "Collects a Windows app files into a single folder"
  task :bundle do
    mkdir_p WIN_BUNDLE_DIR
    mkdir_p WIN_BUNDLE_BACKEND_DIR

    files = Dir["backend/{app/**/*.js,bin/livereload-backend.js,config/*.{json,js},lib/**/*.js,res/*.js,node_modules/{apitree,async,memorystream,plist,sha1,sugar,websocket.io}/**/*.{js,json}}"]
    files.each { |file|  mkdir_p File.dirname(File.join(WIN_BUNDLE_RESOURCES_DIR, file))  }
    files.each { |file|  cp file,             File.join(WIN_BUNDLE_RESOURCES_DIR, file)   }

    cp "Windows/Resources/node.exe", "#{WIN_BUNDLE_RESOURCES_DIR}/node.exe"
    cp "Windows/WinSparkle/WinSparkle.dll", "#{WIN_BUNDLE_DIR}/WinSparkle.dll"

    install_files = files.map { |f| "Resources/#{f}" } + ["Resources/node.exe", "LiveReload.exe"]
    install_files_by_folder = {}
    install_files.each { |file|  (install_files_by_folder[File.dirname(file)] ||= []) << file }

    nsis_spec = []
    install_files_by_folder.sort.each do |folder, files|
      nsis_spec << %Q<\nSetOutPath "$INSTDIR\\#{folder.gsub('/', '\\')}"\n> unless folder == '.'
      files.each do |file|
        nsis_spec << %Q<File "..\\WinApp\\#{file.gsub('/', '\\')}"\n>
      end
    end

    File.open("Windows/files.nsi", "w") { |f| f << nsis_spec.join('') }
  end

  task :rmbundle do
    rm_rf WIN_BUNDLE_DIR
  end

  desc "Recreate a Windows bundle from scratch"
  task :rebundle => [:rmbundle, :bundle]

  desc "Embed version number where it belongs"
  task :version do
      ver = win_version
      WIN_VERSION_FILES.each { |file| subst_version_refs_in_file(file, ver) }
  end

  desc "Tag the current Windows version"
  task :tag do
    sh 'git', 'tag', "win#{win_version}"
  end

  desc "Upload the Windows installer"
  task :upload do
    installer_name = "LiveReload-#{win_version}-Setup.exe"
    installer_path = File.join(BUILDS_DIR, installer_name)
    unless File.exists? installer_path
      fail "Installer does not exist: #{installer_path}"
    end

    sh 's3cmd', '-P', 'put', installer_path, "s3://#{S3_BUCKET}/#{installer_name}"
    puts "http://download.livereload.com.s3.amazonaws.com/#{installer_name}"
    puts "http://download.livereload.com/#{installer_name}"
  end

end

desc "Install all prerequisites, compile all CoffeeScript files"
task 'prepare' => ['backend:prepare']
