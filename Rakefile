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
