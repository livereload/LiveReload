
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
