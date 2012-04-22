ROOT_DIR = File.expand_path('.')
BUILDS_DIR = File.join(ROOT_DIR, 'dist')
# XCODE_RELEASE_DIR = File.expand_path('~/Documents/XBuilds/Release')
XCODE_RELEASE_DIR = File.join(ROOT_DIR, 'LiveReload/build/Release')
TAG_PREFIX = 'v'
S3_BUCKET = 'download.livereload.com'

MAC_BUNDLE_NAME = 'LiveReload.app'
MAC_ZIP_BASE_NAME = "LiveReload"
MAC_SRC = File.join(ROOT_DIR, 'LiveReload')


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

    suffix_for_tag = MacVersion.find_unused_suffix(suffix, '-')
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
    suffix_for_tag = MacVersion.find_unused_suffix(MacVersion.short_version, '-')
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
    suffix = MacVersion.find_unused_suffix("#{MacVersion.short_version}-pre", '')
    Rake::Task['mac:custom'].invoke(suffix)
  end

  desc "Tag, build and zip using the current version number"
  task :dev do |t, args|
    suffix = MacVersion.find_unused_suffix("#{MacVersion.short_version}-dev-#{Time.now.strftime('%b%d').downcase}", '-')
    Rake::Task['mac:custom'].invoke(suffix)
  end

end
