# -*- coding: utf-8 -*-
require 'helper'

class Callable1
  def call(exp)
    exp
  end
end

class Callable2
  def call(exp)
    exp
  end
end

class TestEngine < Temple::Engine
  use(:Parser) do |input|
    [:static, input]
  end
  use :MyFilter1, proc {|exp| exp }
  use :MyFilter2, proc {|exp| exp }
  use Temple::HTML::Pretty, :format, :pretty => true
  filter :MultiFlattener
  generator :ArrayBuffer
  use :BeforeLast, Callable1.new
  wildcard(:Last) { Callable2.new }
end

describe Temple::Engine do
  it 'should build chain' do
    TestEngine.chain.size.should.equal 8

    TestEngine.chain[0].first.should.equal :Parser
    TestEngine.chain[0].size.should.equal 2
    TestEngine.chain[0].last.should.be.instance_of UnboundMethod

    TestEngine.chain[1].first.should.equal :MyFilter1
    TestEngine.chain[1].size.should.equal 2
    TestEngine.chain[1].last.should.be.instance_of UnboundMethod

    TestEngine.chain[2].first.should.equal :MyFilter2
    TestEngine.chain[2].size.should.equal 2
    TestEngine.chain[2].last.should.be.instance_of UnboundMethod

    TestEngine.chain[3].size.should.equal 4
    TestEngine.chain[3].should.equal [:'Temple::HTML::Pretty', Temple::HTML::Pretty, [:format], {:pretty => true}]

    TestEngine.chain[4].size.should.equal 4
    TestEngine.chain[4].should.equal [:MultiFlattener, Temple::Filters::MultiFlattener, [], nil]

    TestEngine.chain[5].size.should.equal 4
    TestEngine.chain[5].should.equal [:ArrayBuffer, Temple::Generators::ArrayBuffer, [], nil]

    TestEngine.chain[6].size.should.equal 2
    TestEngine.chain[6][0].should.equal :BeforeLast
    TestEngine.chain[6][1].should.be.instance_of Callable1

    TestEngine.chain[7].size.should.equal 2
    TestEngine.chain[7][0].should.equal :Last
    TestEngine.chain[7][1].should.be.instance_of UnboundMethod
  end

  it 'should instantiate chain' do
    call_chain = TestEngine.new.send(:call_chain)
    call_chain[0].should.be.instance_of Method
    call_chain[1].should.be.instance_of Method
    call_chain[2].should.be.instance_of Method
    call_chain[3].should.be.instance_of Temple::HTML::Pretty
    call_chain[4].should.be.instance_of Temple::Filters::MultiFlattener
    call_chain[5].should.be.instance_of Temple::Generators::ArrayBuffer
    call_chain[6].should.be.instance_of Callable1
    call_chain[7].should.be.instance_of Callable2
  end

  it 'should have #append' do
    engine = TestEngine.new
    call_chain = engine.send(:call_chain)
    call_chain.size.should.equal 8

    engine.append :MyFilter3 do |exp|
      exp
    end

    TestEngine.chain.size.should.equal 8
    engine.chain.size.should.equal 9
    engine.chain[8].first.should.equal :MyFilter3
    engine.chain[8].size.should.equal 2
    engine.chain[8].last.should.be.instance_of Method

    call_chain = engine.send(:call_chain)
    call_chain.size.should.equal 9
    call_chain[8].should.be.instance_of Method
  end

  it 'should have #prepend' do
    engine = TestEngine.new
    call_chain = engine.send(:call_chain)
    call_chain.size.should.equal 8

    engine.prepend :MyFilter0 do |exp|
      exp
    end

    TestEngine.chain.size.should.equal 8
    engine.chain.size.should.equal 9
    engine.chain[0].first.should.equal :MyFilter0
    engine.chain[0].size.should.equal 2
    engine.chain[0].last.should.be.instance_of Method
    engine.chain[1].first.should.equal :Parser

    call_chain = engine.send(:call_chain)
    call_chain.size.should.equal 9
    call_chain[0].should.be.instance_of Method
  end

  it 'should have #after' do
    engine = TestEngine.new
    engine.after :Parser, :MyFilter0 do |exp|
      exp
    end
    engine.chain.size.should.equal 9
    engine.chain[0].first.should.equal :Parser
    engine.chain[1].first.should.equal :MyFilter0
    engine.chain[2].first.should.equal :MyFilter1
  end

  it 'should have #before' do
    engine = TestEngine.new
    engine.before :MyFilter1, :MyFilter0 do |exp|
      exp
    end
    engine.chain.size.should.equal 9
    engine.chain[0].first.should.equal :Parser
    engine.chain[1].first.should.equal :MyFilter0
    engine.chain[2].first.should.equal :MyFilter1
  end

  it 'should have #remove' do
    engine = TestEngine.new
    engine.remove :MyFilter1
    engine.chain.size.should.equal 7
    engine.chain[0].first.should.equal :Parser
    engine.chain[1].first.should.equal :MyFilter2
  end

  it 'should have #replace' do
    engine = TestEngine.new
    engine.before :Parser, :MyParser do |exp|
      exp
    end
    engine.chain.size.should.equal 9
    engine.chain[0].first.should.equal :MyParser
  end

  it 'should work with inheritance' do
    inherited_engine = Class.new(TestEngine)
    inherited_engine.chain.size.should.equal 8
    inherited_engine.append :MyFilter3 do |exp|
      exp
    end
    inherited_engine.chain.size.should.equal 9
    TestEngine.chain.size.should.equal 8
  end

  it 'should support chain option' do
    engine = TestEngine.new(:chain => proc {|e| e.remove :MyFilter1 })
    TestEngine.chain.size.should.equal 8
    engine.chain.size.should.equal 7
    engine.chain[0].first.should.equal :Parser
    engine.chain[1].first.should.equal :MyFilter2
  end
end
