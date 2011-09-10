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
        when  0 .. 19 then "α#{d}"
        when 20 .. 49 then "β#{d-30}"
        when 40 .. 59 then "rc#{d-60}"
        when 60 .. 79 then ""
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
    puts "http://download.livereload.com.s3.amazonaws.com/LiveReload-#{suffix}.zip"
    puts "http://download.livereload.com/LiveReload-#{suffix}.zip"
  end

end
