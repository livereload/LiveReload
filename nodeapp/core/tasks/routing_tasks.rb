
require 'erb'
require 'ostruct'

class RoutingTasks

  include Rake::DSL

  RoutingTableEntry = OpenStruct

  CLIENT_MSG_ROUTER          = 'app/shared/gen_src/nodeapp_rpc_router.c'
  CLIENT_MSG_ROUTER_SOURCES  = Dir['{nodeapp,app}/**/*.{c,cc,m,mm}'] - [CLIENT_MSG_ROUTER]
  CLIENT_MSG_PROXY_H         = 'app/shared/gen_src/nodeapp_rpc_proxy.h'
  CLIENT_MSG_PROXY_C         = 'app/shared/gen_src/nodeapp_rpc_proxy.c'
  SERVER_MSG_PROXY           = 'backend/config/client-messages.json'
  SERVER_API_DUMPER          = 'backend/bin/livereload-backend-print-apis.js'

  def self.compile_template func_name, args, file
    ERB.new(File.read(file), nil, '%').def_method(RoutingTasks, "#{func_name}(#{args.join(',')})", file)
  end

  def self.compile_templates
    compile_template 'render_client_msg_router', %w(entries), "nodeapp/core/nodeapp_rpc_router.c.erb"
    compile_template 'render_server_msg_proxy',  %w(entries), "#{SERVER_MSG_PROXY}.erb"
    compile_template 'render_client_msg_proxy_h', %w(entries), "nodeapp/core/nodeapp_rpc_proxy.h.erb"
    compile_template 'render_client_msg_proxy_c', %w(entries), "nodeapp/core/nodeapp_rpc_proxy.c.erb"
  end

  def initialize
    desc "Update RPC proxies/routers"
    task :routing do
      self.class.compile_templates

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
  end

end
