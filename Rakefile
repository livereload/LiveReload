#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'rake/clean'
Dir['tasks/*.rb'].each { |file| require file }
Dir['nodeapp/*/tasks/*.rb'].each { |file| require file }

MacVersion = VersionTasks.new('ver:mac', 'app/mac/Info.plist', %w(
    app/mac/src/app_version.h
))

RoutingTasks.new

CopyTask.new :js, 'js/dist/livereload.js', %w(
  extensions/LiveReload.safariextension/livereload.js
  extensions/Chrome/LiveReload/livereload.js
  extensions/Firefox/content/livereload.js
  backend/res/livereload.js
)

desc "Install all prerequisites, compile all CoffeeScript files"
task 'prepare' => ['backend:prepare']

desc "Display some not-so-vital code statistics"
task :stats do
    puts "Backend:        " + `cat $(find backend -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /test) | wc -l`
    puts "Backend tests:  " + `cat $(find backend/test -name '*.coffee' -o -name '*.iced') | wc -l`
    puts "NodeApp:        " + `cat $(find nodeapp -name '*.h' -o -name '*.c' -o -name '*.m' -o -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /lib) | wc -l`
    puts "App:            " + `cat $(find app -name '*.h' -o -name '*.c' -o -name '*.m' -o -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /lib) | wc -l`
    puts "Legacy Shared:  " + `cat $(find ../LR-master/Shared -name '*.h' -o -name '*.c' -o -name '*.m' -o -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /lib | grep -v jansson | grep -v sglib) | wc -l`
    puts "Legacy Mac:     " + `cat $(find ../LR-master/LiveReload -name '*.h' -o -name '*.c' -o -name '*.m' -o -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /lib | grep -v Utilities | grep -v -P "WebSockets/[a-z]" | grep -v Compilers | grep -v JSON) | wc -l`
    puts "Legacy Windows: " + `cat $(find ../LR-master/Windows -name '*.h' -o -name '*.c' -o -name '*.m' -o -name '*.coffee' -o -name '*.iced' | grep -v node_modules | grep -v /lib | grep -v WinSparkle) | wc -l`
end
