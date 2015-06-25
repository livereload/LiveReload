#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'rake/clean'
Dir['tasks/*.rb'].each { |file| require_relative file }

ROOT_DIR = File.expand_path('.')
BUILDS_DIR = File.join(ROOT_DIR, 'dist')
XCODE_RELEASE_DIR = File.join(ROOT_DIR, 'LiveReload/build/Release')
SITE_DIR = File.join(ROOT_DIR, '../site/livereload.com/')
S3_BUCKET = 'download.livereload.com'
MAC_SRC = File.join(ROOT_DIR, 'LiveReload')


MacVersion = VersionTasks.new('mac', 'LiveReload/LiveReload-Info.plist', %w(
  LiveReload/Classes/Application/version.h
))
MacBuild = MacBuildTasks.new('mac', :version_tasks => MacVersion, :bundle_name => 'LiveReload.app', :zip_base_name => 'LiveReload', :tag_prefix => 'v', :channel => 'beta', :target => 'LiveReload')

SnowLeopardVersion = VersionTasks.new('snowleo', 'LiveReload/LiveReload Snow Leopard Info.plist', %w(
  LiveReload/Classes/Application/version_legacy.h
))
SnowLeopardBuild = MacBuildTasks.new('snowleo', :version_tasks => SnowLeopardVersion, :bundle_name => 'LiveReload Snow Leopard.app', :zip_base_name => 'LiveReload-SnowLeopard', :tag_prefix => 'snowleo', :channel => 'snowleo', :target => 'LiveReload (10.6)')

MASVersion = VersionTasks.new('mas', 'LiveReload/LiveReload-Info-MAS.plist', %w(
  LiveReload/Classes/Application/version_mas.h
))
MacAppStoreBuildTasks.new('mas', :version_tasks => MASVersion, :tag_prefix => 'mas', :scheme => 'LiveReload (MAS)')


def subst_version_refs_in_file file, ver
    puts file
    orig = File.read(file)
    prev_line = ""
    anything_matched = false
    data = orig.lines.map do |line|
        if line =~ /\d\.\d\.\d/ && (line =~ /version/i || prev_line =~ /CFBundleShortVersionString|CFBundleVersion/)
            anything_matched = true
            new_line = line.gsub /\d\.\d\.\d+/, ver
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
file 'backend/res/livereload.js' => ['js/dist/livereload.js'] do |t|
  mkdir_p File.dirname(t.name)
  cp t.prerequisites.first, t.name
end

desc "Update LiveReload.js from js/dist/"
task :js => ['LiveReload/livereload.js', 'extensions/LiveReload.safariextension/livereload.js', 'extensions/Chrome/LiveReload/livereload.js', 'extensions/Firefox/content/livereload.js', 'backend/res/livereload.js']

desc "Push all Git changes"
task :push do
  Dir.chdir 'LiveReload/Compilers' do
    sh 'git', 'push'
    sh 'git', 'push', '--tags'
  end
  sh 'git', 'push'
  sh 'git', 'push', '--tags'
end



################################################################################
# Routing

require 'erb'
require 'ostruct'

def compiler_template func_name, args, file
  ERB.new(File.read(file), nil, '%').def_method(Object, "#{func_name}(#{args.join(',')})", file)
end

RoutingTableEntry = OpenStruct

CLIENT_MSG_ROUTER          = 'Shared/msg_router.c'
CLIENT_MSG_ROUTER_SOURCES  = Dir['{Shared,Windows,LiveReload}/**/*.{c,m}'] - [CLIENT_MSG_ROUTER]
CLIENT_MSG_PROXY_H         = 'Shared/msg_proxy.h'
CLIENT_MSG_PROXY_C         = CLIENT_MSG_PROXY_H.ext('c')
SERVER_MSG_PROXY           = 'backend/config/client-messages.json'
SERVER_API_DUMPER          = 'backend/bin/livereload-backend-print-apis.js'

compiler_template 'render_client_msg_router', %w(entries), "#{CLIENT_MSG_ROUTER}.erb"
compiler_template 'render_server_msg_proxy',  %w(entries), "#{SERVER_MSG_PROXY}.erb"
compiler_template 'render_client_msg_proxy_h', %w(entries), "#{CLIENT_MSG_PROXY_H}.erb"
compiler_template 'render_client_msg_proxy_c', %w(entries), "#{CLIENT_MSG_PROXY_C}.erb"

task :routing do
  existing_names = {}
  entries = CLIENT_MSG_ROUTER_SOURCES.map do |file|
    lines = File.read(file).lines
    names = lines.map { |line| [$1, $2] if line =~ /^(void\s+|json_t\s*\*\s*)C_(\w+)\s*\(/ }.compact
    names.map { |type, name|
      next if existing_names[name]
      existing_names[name] = true

      puts "C_#{name}"
      entry = RoutingTableEntry.new(:func_name => "C_#{name}", :msg_name => name.gsub('__', '.'), :return_type => type, :needs_wrapper => (type =~ /^void/))
      if entry.needs_wrapper
        entry.wrapper_name = entry.func_to_call = "_#{entry.func_name}_wrapper"
      else
        entry.func_to_call = entry.func_name
      end
      entry
    }
  end.flatten.compact

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


################################################################################
# Windows

desc "Install all prerequisites, compile all CoffeeScript files"
task 'prepare' => ['backend:prepare']
