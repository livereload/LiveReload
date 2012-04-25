
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

    desc "Install all backend prerequisites & compile all CoffeeScript sources"
    task :prepare => ['backend:install', 'backend:compile']

    desc "Remove all compiled JavaScript files in the backend"
    task :clobber do
        rm COFFEE_DST + ICED_DST
    end

    desc "Run tests"
    task :test do
        puts "Invoking tests."
        Dir.chdir 'backend' do
            sh 'LRPortOverride=35727 ./run-tests --growl -R spec test/**/*_test.js'
        end
    end

    desc "Produce a test coverage report"
    task :coverage do
        unless File.exist? 'backend/lib-src'
            sh 'cd backend; mv lib lib-src'
            sh 'cd backend; ln -s lib-src lib'
        end
        rm_rf 'backend/lib-cov'
        sh 'jscoverage backend/lib-src backend/lib-cov'
        sh 'rm backend/lib'
        sh 'cd backend; ln -s lib-cov lib'
        puts "Invoking tests."
        Dir.chdir 'backend' do
            sh 'LRPortOverride=35727 ./run-tests -R html-cov test/**/*_test.js >coverage.html' rescue nil
        end
        rm_rf 'backend/lib-cov'
        sh 'open', 'backend/coverage.html'
        Rake::Task['backend:uncover'].invoke
    end

    desc "Cleanup after running test coverage"
    task :uncover do
        if File.exist? 'backend/lib-src'
            sh 'cd backend; rm lib; mv lib-src lib'
        end
    end

    desc "Run tests automatically when a backend JavaScript file is modified"
    task :autotest do
        require 'listen'
        Rake::Task['backend:test'].invoke rescue nil
        puts "\nAutotest waiting for changes.\n"
        Listen.to('backend', :filter => /\.js$/) do |modified, added, removed|
            Rake::Task.tasks.each { |task| task.reenable }
            Rake::Task['backend:test'].invoke rescue nil
            puts "\nAutotest waiting for changes.\n"
        end
    end

end
