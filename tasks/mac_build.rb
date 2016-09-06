
class BaseMacBuildTasks

  def tag!
    tag = @tag_format.gsub('1.2.3', @version_tasks.short_version)

    sh 'git', 'tag', '-a', '-f', '-m', "#{tag}", tag

    Dir.chdir 'LiveReload/Compilers' do
      sh 'git', 'tag', '-a', '-f', '-m', "#{tag}", tag
    end
  end

  def define_tag_task!
    desc "Tag (just like the build task does)"
    task "#{@prefix}:tag" do
      tag!
    end
  end

end

class MacBuildTasks < BaseMacBuildTasks
  include Rake::DSL

  def initialize prefix, options
    @prefix        = prefix
    @version_tasks = options[:version_tasks]
    @bundle_name   = options[:bundle_name]
    @zip_base_name = options[:zip_base_name]
    @tag_format    = options[:tag_format]
    @channel       = options[:channel]
    @target        = options[:target]

    define_tag_task!

    desc "Upload the current version's build to S3"
    task "#{prefix}:upload" do
      suffix = @version_tasks.short_version
      zip_name = "#{@zip_base_name}-#{suffix}.zip"
      zip_path_in_builds = File.join(BUILDS_DIR, zip_name)

      sh 's3cmd', '-P', 'put', zip_path_in_builds, "s3://#{S3_BUCKET}/#{zip_name}"
      puts "http://#{S3_BUCKET}/#{zip_name}"
      puts "https://s3.amazonaws.com/#{S3_BUCKET}/#{zip_name}"
    end

    desc "Add the current version into the web site's versions_mac.yml"
    task "#{prefix}:publish" do |t, args|
      suffix = @version_tasks.short_version
      zip_name = "#{@zip_base_name}-#{suffix}.zip"
      date = Time.new.strftime('%Y-%m-%d')
      versions_file = File.join(SITE_DIR, '_data/versions_mac.yml')
      url = "https://s3.amazonaws.com/#{S3_BUCKET}/#{zip_name}"

      require 'net/http'
      require 'uri'
      uri = URI(url)
      file_size = nil
      puts "Getting the size of #{url}..."
      Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
        response = http.request_head(url)
        file_size = response['content-length'].to_i
      end
      
      snippet = <<-END
- version: "#{suffix}"
  date: #{date}
  channels:
    production: no
    #{@channel}: yes
  url: "https://s3.amazonaws.com/#{S3_BUCKET}/#{zip_name}"
  file_size: #{file_size}
  release_notes:
    - title: TODO
      details: TODO
    END

      content = snippet + "\n" + File.read(versions_file)
      File.open(versions_file, 'w') { |f| f.write content } 
      
      sh 'subl', versions_file

      puts
      puts "To publish the beta site:"
      puts
      puts "    cd #{File.expand_path(SITE_DIR).sub(ENV['HOME'], '~')}"
      puts "    jekyll serve"
      puts "    open http://0.0.0.0:4000/beta/"
      puts "    s3_website ..."
      puts
    end

    desc "Build and zip using the current version number"
    task "#{prefix}:build" do |t, args|
      suffix = @version_tasks.short_version

      zip_name = "#{@zip_base_name}-#{suffix}.zip"
      zip_path = File.join(XCODE_RELEASE_DIR, zip_name)
      zip_path_in_builds = File.join(BUILDS_DIR, zip_name)
      mac_bundle_path = File.join(XCODE_RELEASE_DIR, @bundle_name)

      rm_f zip_path
      rm_rf @bundle_name

      Dir.chdir MAC_SRC do
        sh 'xcodebuild clean'
        sh 'xcodebuild', '-target', @target
      end

      puts
      puts "Checking code signature after build."
      sh 'spctl', '-a', '--verbose=4', mac_bundle_path

      Dir.chdir XCODE_RELEASE_DIR do
        rm_rf zip_name
        sh 'zip', '-9rXy', zip_name, @bundle_name
      end

      mkdir_p File.dirname(zip_path_in_builds)
      cp zip_path, zip_path_in_builds

      Dir.chdir BUILDS_DIR do
        rm_rf @bundle_name
        sh 'unzip', '-q', zip_name

        puts
        puts "Checking code signature after unzipping."
        sh 'spctl', '-a', '--verbose=4', @bundle_name
      end

      tag!

      sh 'open', '-R', zip_path_in_builds
    end
  end

end


class MacAppStoreBuildTasks < BaseMacBuildTasks
  include Rake::DSL

  def initialize prefix, options
    @prefix        = prefix
    @version_tasks = options[:version_tasks]
    @tag_format    = options[:tag_format]
    @scheme        = options[:scheme]

    define_tag_task!

    desc "Build and archive using the current version number"
    task "#{prefix}:archive" do |t, args|
      suffix = @version_tasks.short_version

      Dir.chdir MAC_SRC do
        sh 'xcodebuild', 'clean', '-scheme', @scheme
        sh 'xcodebuild', 'archive', '-scheme', @scheme
      end

      tag!
    end
  end

end
