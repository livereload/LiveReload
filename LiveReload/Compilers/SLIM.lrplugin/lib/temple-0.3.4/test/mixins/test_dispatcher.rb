require 'helper'

class FilterWithDispatcherMixin
  include Temple::Mixins::Dispatcher

  def on_test(arg)
    [:on_test, arg]
  end

  def on_second_test(arg)
    [:on_second_test, arg]
  end
end

describe Temple::Mixins::Dispatcher do
  before do
    @filter = FilterWithDispatcherMixin.new
  end

  it 'should return unhandled expressions' do
    @filter.call([:unhandled]).should.equal [:unhandled]
  end

  it 'should dispatch first level' do
    @filter.call([:test, 42]).should.equal [:on_test, 42]
  end

  it 'should dispatch second level' do
    @filter.call([:second, :test, 42]).should.equal [:on_second_test, 42]
  end
end
