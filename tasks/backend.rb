
BACKEND_DIR = 'backend'

COFFEE_SRC = FileList["#{BACKEND_DIR}/{app,bin,config,lib,logs,test}/**/*.coffee"]
COFFEE_DST = COFFEE_SRC.ext('js')

ICED_SRC = FileList["#{BACKEND_DIR}/{app,bin,config,lib,logs,test}/**/*.iced"]
ICED_DST = COFFEE_SRC.ext('js')

CLOBBER.include COFFEE_DST + ICED_DST

namespace :backend do

    desc "Compile all CoffeeScript sources into JavaScript"
    task :compile do
        unless (`coffee --version` rescue '') =~ /CoffeeScript version 1\./
            puts
            puts "Please install CoffeeScript:"
            puts
            puts "  npm install coffee-script -g"
            puts
            exit
        end
        unless (`iced --version` rescue '') =~ /IcedCoffeeScript version 1\./
            puts
            puts "Please install IcedCoffeeScript:"
            puts
            puts "  npm install iced-coffee-script -g"
            puts
            exit
        end
        sh 'coffee', '-c', *COFFEE_SRC
        sh 'iced', '--runtime', 'inline', '-c', *ICED_SRC
    end

    desc "Install all backend prerequisites"
    task :install do
        sh 'npm', 'install', 'coffee-script', 'iced-coffee-script', '-g'
        Dir.chdir(BACKEND_DIR) do
            sh 'npm', 'install'
        end
    end

    desc "Copy relevant backend files"
    task :bundle do
        files = `cd backend; node_modules/pathspec/bin/pathspec-find.js . '*.js' '*.node' '*.json' '*.md' '!**/ws/examples' '!test' '!tests' '!unit_tests' '!**/sugar/release' '!example' '!examples' '!pyyaml-src' '!*.tmbundle' '!.bin' '!mocha'`.split("\n").sort
        rm_rf 'interim/backend'
        for file in files
            dst = "interim/backend/#{file}"
            mkdir_p File.dirname(dst)
            cp "backend/#{file}", dst
        end
    end

    desc "Install all backend prerequisites & compile all CoffeeScript sources"
    task :prepare => ['backend:install', 'backend:compile', 'backend:bundle']

    desc "Remove all compiled JavaScript files in the backend"
    task :clobber do
        rm COFFEE_DST + ICED_DST
    end

end
