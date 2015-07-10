
class VersionTasks
  include Rake::DSL

  def initialize prefix, src_file, dst_files
    @src_file = src_file
    @dst_files = dst_files

    desc "Print the current app version"
    task "#{prefix}:version" do
      puts version
    end

    desc "Update Info.plist according to the current CFBundleVersion"
    task "#{prefix}:propagate" do
      marketing_version = marketing_for_internal_version(version)
      PList.set @src_file, 'CFBundleShortVersionString', marketing_version
      @dst_files.each { |file|  subst_version_refs_in_file file, marketing_version }
    end

    desc "Bump version number to the specified one"
    task "#{prefix}:bump", :version do |t, args|
      if comparable_version_for(args[:version]) <= comparable_version_for(version)
        raise "New version #{args[:version]} is less than the current version #{version}"
      end

      PList.set @src_file, 'CFBundleVersion', args[:version]
      Rake::Task["#{prefix}:propagate"].invoke()

      sh 'git', 'add', @src_file, *@dst_files
      sh 'git', 'commit', '-v', '-e', '-m', "Version bump to #{short_version}"
    end
  end

  def version
    PList.get(@src_file, 'CFBundleVersion').split('.').collect { |x| "#{x.to_i}" }.join('.')
  end

  def marketing_version
    marketing_for_internal_version(version)
  end

  def short_version
    marketing_for_internal_version(version).gsub('α', 'a').gsub('β', 'b').gsub(' ', '')
  end

private

  def marketing_for_internal_version version, greek=true
    a, b, c, d = version.split('.').collect { |x| x.to_i }
    x = case d
          when  0 .. 29 then "α#{d}"
          when 30 .. 49 then "β#{d-30}"
          when 50 .. 69 then "rc#{d-60}"
          when 70 .. 89 then ""
          when nil      then ""
          else               "unk#{d}"
        end

    result = "#{a}.#{b}"
    result += ".#{c}" if c && c > 0
    result += " #{x}" unless x.empty?
    return result
  end

  def comparable_version_for version
    version.split('.').collect { |x| sprintf("%02d", x) }.join('.')
  end

  def subst_version_refs_in_file file, ver
      puts file
      orig = File.read(file)
      prev_line = ""
      anything_matched = false
      data = orig.lines.map do |line|
          if line =~ /\d{1,2}\.\d{1,2}\.\d{1,2}/ && (line =~ /version/i || prev_line =~ /CFBundleShortVersionString|CFBundleVersion/)
              anything_matched = true
              new_line = line.gsub /\d{1,2}\.\d{1,2}\.\d{1,3}/, ver
              puts "    #{new_line.strip}"
          else
              new_line = line
          end
          prev_line = line
          new_line
      end.join('')

      raise "Error: no substitutions made in #{file}" unless anything_matched

      File.open(file, 'w') { |f| f.write data }
  end

end
