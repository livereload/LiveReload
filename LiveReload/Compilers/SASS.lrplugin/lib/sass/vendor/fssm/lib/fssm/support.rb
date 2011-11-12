require 'rbconfig'

module FSSM::Support
  class << self
    def usable_backend
      choice = case
                 when mac? && !lion? && !jruby? && carbon_core?
                   'FSEvents'
                 when mac? && rb_fsevent?
                   'RBFSEvent'
                 when linux? && rb_inotify?
                   'Inotify'
                 else
                   'Polling'
               end

      if (mac? || linux?) && choice == 'Polling'
        optimal = case
                    when mac?
                      'rb-fsevent'
                    when linux?
                      'rb-inotify'
                  end
        FSSM.dbg("An optimized backend is available for this platform!")
        FSSM.dbg("    gem install #{optimal}")
      end

      choice
    end

    def backend
      @@backend ||= usable_backend
    end

    def jruby?
      defined?(JRUBY_VERSION)
    end

    def mac?
      Config::CONFIG['target_os'] =~ /darwin/i
    end

    def lion?
      Config::CONFIG['target_os'] =~ /darwin11/i
    end

    def linux?
      Config::CONFIG['target_os'] =~ /linux/i
    end

    def carbon_core?
      begin
        require 'osx/foundation'
        OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
        true
      rescue LoadError
        false
      end
    end

    def rb_fsevent?
      begin
        require 'rb-fsevent'
        defined?(FSEvent::VERSION) ? FSEvent::VERSION.to_f >= 0.4 : false
      rescue LoadError
        false
      end
    end

    def rb_inotify?
      begin
        require 'rb-inotify'
        if defined?(INotify::VERSION)
          version = INotify::VERSION
          version[0] > 0 || version[1] >= 6
        end
      rescue LoadError
        false
      end
    end

    def use_block(context, block)
      return if block.nil?
      if block.arity == 1
        block.call(context)
      else
        context.instance_eval(&block)
      end
    end

  end
end
