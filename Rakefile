ROOT_DIR = File.expand_path('.')
BUILDS_DIR = File.join(ROOT_DIR, 'dist')
XCODE_RELEASE_DIR = File.expand_path('~/Documents/XBuilds/Release')
TAG_PREFIX = 'v'
S3_BUCKET = 'download.livereload.com'

MAC_BUNDLE_NAME = 'LiveReload.app'
MAC_ZIP_BASE_NAME = "LiveReload"
MAC_SRC = File.join(ROOT_DIR, 'LiveReload')
INFO_PLIST = File.join(MAC_SRC, 'LiveReload-Info.plist')

module PList
  class << self
    def get file_name, key
      if File.read(file_name) =~ %r!<key>#{Regexp.escape(key)}</key>\s*<string>(.*?)</string>!
        $1.strip
      else
        nil
      end
    end
    def set file_name, key, value
      text = File.read(file_name).gsub(%r!(<key>#{Regexp.escape(key)}</key>\s*<string>).*?(</string>)!) {
        "#{$1}#{value}#{$2}"
      }
      File.open(file_name, 'w') { |f| f.write text }
    end
  end
end


def marketing_for_internal_version version, greek=true
  a, b, c, d = version.split('.').collect { |x| x.to_i }
  x = case d
        when  0 .. 29 then "α#{d}"
        when 30 .. 49 then "β#{d-30}"
        when 50 .. 69 then "rc#{d-60}"
        when 70 .. 89 then ""
        else               "unk#{d}"
      end

  result = "#{a}.#{b}"
  result += ".#{c}" if c > 0
  result += " #{x}" unless x.empty?
  return result
end

def comparable_version_for version
  version.split('.').collect { |x| sprintf("%02d", x) }.join('.')
end


module TheApp

  def self.version
    PList.get(INFO_PLIST, 'CFBundleVersion').split('.').collect { |x| "#{x.to_i}" }.join('.')
  end

  def self.marketing_version
    marketing_for_internal_version(self.version)
  end

  def self.short_version
    marketing_for_internal_version(self.version).gsub('α', 'a').gsub('β', 'b').gsub(' ', '')
  end

  def self.find_unused_suffix prefix, separator
    all_tags = `git tag`.strip.split("\n")
    suffix = "#{prefix}"
    index = 1
    while all_tags.include?("#{TAG_PREFIX}#{suffix}")
      index += 1
      suffix = "#{prefix}#{separator}#{index}"
    end
    return suffix
  end

end


namespace :version do

  desc "Print the current app version"
  task :show do
    puts TheApp.version
  end

  desc "Update Info.plist according to the current CFBundleVersion"
  task :update do
    marketing_version = marketing_for_internal_version(TheApp.version)
    PList.set INFO_PLIST, 'CFBundleShortVersionString', marketing_version
  end

  desc "Bump version number to the specified one"
  task :bump, :version do |t, args|
    if comparable_version_for(args[:version]) <= comparable_version_for(TheApp.version)
      raise "New version #{args[:version]} is less than the current version #{TheApp.version}"
    end

    PList.set INFO_PLIST, 'CFBundleVersion', args[:version]
    Rake::Task['version:update'].invoke()

    sh 'git', 'add', INFO_PLIST
    sh 'git', 'commit', '-v', '-e', '-m', "Bump version number to #{TheApp.short_version}"
  end

end

namespace :build do

  desc "Upload the given build to S3"
  task :upload, :suffix do |t, args|
    zip_name = "#{MAC_ZIP_BASE_NAME}-#{args[:suffix]}.zip"
    zip_path_in_builds = File.join(BUILDS_DIR, zip_name)

    sh 's3cmd', '-P', 'put', zip_path_in_builds, "s3://#{S3_BUCKET}/#{zip_name}"
  end

  desc "Tag, build and zip using a custom suffix"
  task :custom, :suffix do |t, args|
    suffix = args[:suffix]
    raise "Suffix is required for build:custom" if suffix.empty?

    suffix_for_tag = TheApp.find_unused_suffix(suffix, '-')
    tag = "#{TAG_PREFIX}#{suffix_for_tag}"
    sh 'git', 'tag', tag

    zip_name = "#{MAC_ZIP_BASE_NAME}-#{suffix}.zip"
    zip_path = File.join(XCODE_RELEASE_DIR, zip_name)
    zip_path_in_builds = File.join(BUILDS_DIR, zip_name)

    Dir.chdir MAC_SRC do
      sh 'xcodebuild clean'
      sh 'xcodebuild'
    end
    Dir.chdir XCODE_RELEASE_DIR do
      sh 'zip', '-9rX', zip_name, MAC_BUNDLE_NAME
    end

    mkdir_p File.dirname(zip_path_in_builds)
    cp zip_path, zip_path_in_builds

    sh 'open', '-R', zip_path_in_builds

    Rake::Task['build:upload'].invoke(suffix)

    sh 'git', 'tag'

    puts "http://download.livereload.com.s3.amazonaws.com/LiveReload-#{suffix}.zip"
    puts "http://download.livereload.com/LiveReload-#{suffix}.zip"
  end

  desc "Tag, build and zip using the current version number"
  task :release do |t, args|
    Rake::Task['build:custom'].invoke(TheApp.short_version)
  end

  desc "Tag, build and zip using the current version number suffixed with -pre"
  task :prerelease do |t, args|
    suffix = TheApp.find_unused_suffix("#{TheApp.short_version}-pre", '')
    Rake::Task['build:custom'].invoke(suffix)
  end

  desc "Tag, build and zip using the current version number"
  task :dev do |t, args|
    suffix = TheApp.find_unused_suffix("#{TheApp.short_version}-dev-#{Time.now.strftime('%b%d').downcase}", '-')
    Rake::Task['build:custom'].invoke(suffix)
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

desc "Update LiveReload.js from js/dist/"
task :js => ['LiveReload/livereload.js', 'extensions/LiveReload.safariextension/livereload.js', 'extensions/Chrome/LiveReload/livereload.js', 'extensions/Firefox/content/livereload.js']


namespace :site do
  desc "Publish the web site"
  task :publish do
    sh 'rsync', '-avz', 'site/', 'andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/'
  end
end



################################################################################
# Windows

require 'erb'
require 'ostruct'

def compiler_template func_name, args, file
  ERB.new(File.read(file), nil, '%').def_method(Object, "#{func_name}(#{args.join(',')})", file)
end

RoutingTableEntry = OpenStruct

CLIENT_MSG_ROUTER          = 'Shared/msg_router.c'
CLIENT_MSG_ROUTER_SOURCES  = Dir['{Shared,Windows}/**/*.c'] - [CLIENT_MSG_ROUTER]
CLIENT_MSG_PROXY_H         = 'Shared/msg_proxy.h'
CLIENT_MSG_PROXY_C         = CLIENT_MSG_PROXY_H.ext('c')
SERVER_MSG_PROXY           = 'backend/config/client-messages.json'
SERVER_API_DUMPER          = 'backend/bin/livereload-backend-print-apis.js'

compiler_template 'render_client_msg_router', %w(entries), "#{CLIENT_MSG_ROUTER}.erb"
compiler_template 'render_server_msg_proxy',  %w(entries), "#{SERVER_MSG_PROXY}.erb"
compiler_template 'render_client_msg_proxy_h', %w(entries), "#{CLIENT_MSG_PROXY_H}.erb"
compiler_template 'render_client_msg_proxy_c', %w(entries), "#{CLIENT_MSG_PROXY_C}.erb"

task :routing do
  entries = CLIENT_MSG_ROUTER_SOURCES.map do |file|
    lines = File.read(file).lines
    names = lines.map { |line| [$1, $2] if line =~ /^(void\s+|json_t\s*\*\s*)C_(\w+)\s*\(/ }.compact
    names.map { |type, name|
      puts "C_#{name}"
      entry = RoutingTableEntry.new(:func_name => "C_#{name}", :msg_name => name.gsub('__', '.'), :return_type => type, :needs_wrapper => (type =~ /^void/))
      if entry.needs_wrapper
        entry.wrapper_name = entry.func_to_call = "_#{entry.func_name}_wrapper"
      else
        entry.func_to_call = entry.func_name
      end
      entry
    }
  end.flatten

  File.open(CLIENT_MSG_ROUTER, 'w') { |f| f.write render_client_msg_router(entries) }
  File.open(SERVER_MSG_PROXY,  'w') { |f| f.write render_server_msg_proxy(entries) }

  entries = `node #{SERVER_API_DUMPER}`.strip.split("\n").map do |msg_name|
    func_name = "S_" + msg_name.gsub('.', '_').gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2.downcase}" }
    puts func_name
    RoutingTableEntry.new :func_name => func_name, :msg_name => msg_name
  end

  File.open(CLIENT_MSG_PROXY_H, 'w') { |f| f.write render_client_msg_proxy_h(entries) }
  File.open(CLIENT_MSG_PROXY_C, 'w') { |f| f.write render_client_msg_proxy_c(entries) }
end
