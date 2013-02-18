
require 'erb'
require 'ostruct'

class RoutingTasks

  include Rake::DSL

  RoutingTableEntry = OpenStruct

  def self.compile_template func_name, args, file
    ERB.new(File.read(file), nil, '%').def_method(RoutingTasks, "#{func_name}(#{args.join(',')})", file)
  end

  def self.compile_templates
    compile_template 'render_client_msg_router', %w(entries), "nodeapp/core/src/nodeapp_rpc_router.c.erb"
    compile_template 'render_server_msg_proxy',  %w(entries), "nodeapp/core/js/client-messages.json.erb"
    compile_template 'render_client_msg_proxy_h', %w(entries), "nodeapp/core/src/nodeapp_rpc_proxy.h.erb"
    compile_template 'render_client_msg_proxy_c', %w(entries), "nodeapp/core/src/nodeapp_rpc_proxy.c.erb"
  end

  def initialize options
    @app_src       = options[:app_src]              or raise "RoutingTasks.new requires :app_src"
    @gen_src       = options[:gen_src]              or raise "RoutingTasks.new requires :gen_src"
    @messages_json = options[:messages_json]        or raise "RoutingTasks.new requires :messages_json"
    @api_dumper_js = options[:api_dumper_js]        or raise "RoutingTasks.new requires :api_dumper_js"

    @client_msg_router          = "#{@gen_src}/nodeapp_rpc_router.c"
    @client_msg_router_sources  = Dir["{nodeapp,#{@app_src}}/**/*.{c,cc,m,mm}"] - [@client_msg_router]
    @client_msg_proxy_h         = "#{@gen_src}/nodeapp_rpc_proxy.h"
    @client_msg_proxy_c         = "#{@gen_src}/nodeapp_rpc_proxy.c"
    @server_msg_proxy           = @messages_json
    @server_api_dumper          = @api_dumper_js

    desc "Update RPC proxies/routers in #{@gen_src} by scanning {nodeapp,#{@app_src}}/**/*.{c,cc,m,mm}"
    task :routing do
      self.class.compile_templates

      existing_names = {}
      entries = @client_msg_router_sources.map do |file|
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

      File.open(@client_msg_router, 'w') { |f| f.write render_client_msg_router(entries) }
      File.open(@server_msg_proxy,  'w') { |f| f.write render_server_msg_proxy(entries) }

      entries = `node #{@server_api_dumper}`.strip.split("\n").map do |msg_name|
        func_name = "S_" + msg_name.gsub('.', '_').gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2.downcase}" }
        puts func_name
        RoutingTableEntry.new :func_name => func_name, :msg_name => msg_name
      end

      File.open(@client_msg_proxy_h, 'w') { |f| f.write render_client_msg_proxy_h(entries) }
      File.open(@client_msg_proxy_c, 'w') { |f| f.write render_client_msg_proxy_c(entries) }
    end
  end

end
