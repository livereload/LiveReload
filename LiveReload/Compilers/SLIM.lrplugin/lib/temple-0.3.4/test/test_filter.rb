require 'helper'

class SimpleFilter < Temple::Filter
  def on_test(arg)
    [:on_test, arg]
  end
end

describe Temple::Filter do
  it 'should support options' do
    Temple::Filter.should.respond_to :default_options
    Temple::Filter.should.respond_to :set_default_options
    Temple::Filter.new.options.should.be.instance_of Temple::ImmutableHash
    Temple::Filter.new(:key => 3).options[:key].should.equal 3
  end

  it 'should implement call' do
    Temple::Filter.new.call([:exp]).should.equal [:exp]
  end

  it 'should process expressions' do
    filter = SimpleFilter.new
    filter.call([:unhandled]).should.equal [:unhandled]
    filter.call([:test, 42]).should.equal [:on_test, 42]
  end
end
