require 'bacon'
require 'temple'

module TestHelper
  def with_html_safe(flag)
    String.send(:define_method, :html_safe?) { flag }
    yield
  ensure
    String.send(:undef_method, :html_safe?) if String.method_defined?(:html_safe?)
  end

  def grammar_validate(grammar, exp, message)
    lambda { grammar.validate!(exp) }.should.raise(Temple::InvalidExpression).message.should.equal message
  end

  def erb(src, options = {})
    Temple::ERB::Template.new(options) { src }.render
  end
end

class Bacon::Context
  include TestHelper
end
