module Temple
  # @api public
  module Templates
    autoload :Tilt,  'temple/templates/tilt'
    autoload :Rails, 'temple/templates/rails'

    def self.method_missing(name, engine, options = {})
      template = Class.new(const_get(name))
      template.default_options[:engine] = engine
      template.default_options.update(options)
      template.register_as(options[:register_as]) if options[:register_as]
      template
    end
  end
end
