module Temple
  module Mixins
    # @api private
    module EngineDSL
      def chain_modified!
      end

      def append(*args, &block)
        chain << element(args, block)
        chain_modified!
      end

      def prepend(*args, &block)
        chain.unshift(element(args, block))
        chain_modified!
      end

      def remove(name)
        found = false
        chain.reject! do |i|
          equal = i.first == name
          found = true if equal
          equal
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      alias use append

      def before(name, *args, &block)
        name = Class === name ? name.name.to_sym : name
        raise(ArgumentError, 'First argument must be Class or Symbol') unless Symbol === name
        e = element(args, block)
        found, i = false, 0
        while i < chain.size
          if chain[i].first == name
            found = true
            chain.insert(i, e)
            i += 2
          else
            i += 1
          end
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      def after(name, *args, &block)
        name = Class === name ? name.name.to_sym : name
        raise(ArgumentError, 'First argument must be Class or Symbol') unless Symbol === name
        e = element(args, block)
        found, i = false, 0
        while i < chain.size
          if chain[i].first == name
            found = true
            i += 1
            chain.insert(i, e)
          end
          i += 1
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      def replace(name, *args, &block)
        name = Class === name ? name.name.to_sym : name
        raise(ArgumentError, 'First argument must be Class or Symbol') unless Symbol === name
        e = element(args, block)
        found = false
        chain.each_with_index do |c, i|
          if c.first == name
            found = true
            chain[i] = e
          end
        end
        raise "#{name} not found" unless found
        chain_modified!
      end

      def filter(name, *options, &block)
        use(name, Temple::Filters.const_get(name), *options, &block)
      end

      def generator(name, *options, &block)
        use(name, Temple::Generators.const_get(name), *options, &block)
      end

      def wildcard(name, &block)
        raise(ArgumentError, 'Block must have arity 0') unless block.arity <= 0
        chain << [name, define_chain_method("WILDCARD #{name}", block)]
        chain_modified!
      end

      private

      def define_chain_method(name, proc)
        if Class === self
          define_method(name, &proc)
          instance_method(name)
        else
          (class << self; self; end).class_eval { define_method(name, &proc) }
          method(name)
        end
      end

      def element(args, block)
        name = args.shift
        if Class === name
          filter = name
          name = filter.name.to_sym
        end
        raise(ArgumentError, 'First argument must be Class or Symbol') unless Symbol === name

        if block
          raise(ArgumentError, 'Class and block argument are not allowed at the same time') if filter
          filter = block
        end

        filter ||= args.shift

        case filter
        when Proc
          # Proc or block argument
          # The proc is converted to a method of the engine class.
          # The proc can then access the option hash of the engine.
          raise(ArgumentError, 'Too many arguments') unless args.empty?
          raise(ArgumentError, 'Proc or blocks must have arity 1') unless filter.arity == 1
          [name, define_chain_method("FILTER #{name}", filter)]
        when Class
          # Class argument (e.g Filter class)
          # The options are passed to the classes constructor.
          local_options = Hash === args.last ? args.pop : nil
          raise(ArgumentError, 'Only symbols allowed in option filter') unless args.all? {|o| Symbol === o }
          [name, filter, args, local_options]
        else
          # Other callable argument (e.g. Object of class which implements #call or Method)
          # The callable has no access to the option hash of the engine.
          raise(ArgumentError, 'Too many arguments') unless args.empty?
          raise(ArgumentError, 'Class or callable argument is required') unless filter.respond_to?(:call)
          [name, filter]
        end
      end
    end
  end
end
