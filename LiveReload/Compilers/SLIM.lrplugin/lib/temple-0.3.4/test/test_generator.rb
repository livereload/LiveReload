require 'helper'

class SimpleGenerator < Temple::Generator
  def preamble
    "#{buffer} = BUFFER"
  end

  def postamble
    buffer
  end

  def on_static(s)
    concat "S:#{s}"
  end

  def on_dynamic(s)
    concat "D:#{s}"
  end

  def on_code(s)
    "C:#{s}"
  end
end

describe Temple::Generator do
  it 'should compile simple expressions' do
    gen = SimpleGenerator.new

    gen.call([:static,  'test']).should.equal '_buf = BUFFER; _buf << (S:test); _buf'
    gen.call([:dynamic, 'test']).should.equal '_buf = BUFFER; _buf << (D:test); _buf'
    gen.call([:code,    'test']).should.equal '_buf = BUFFER; C:test; _buf'
  end

  it 'should compile multi expression' do
    gen = SimpleGenerator.new(:buffer => "VAR")
    gen.call([:multi,
      [:static, "static"],
      [:dynamic, "dynamic"],
      [:code, "code"]
    ]).should.equal 'VAR = BUFFER; VAR << (S:static); VAR << (D:dynamic); C:code; VAR'
  end

  it 'should compile capture' do
    gen = SimpleGenerator.new(:buffer => "VAR", :capture_generator => SimpleGenerator)
    gen.call([:capture, "foo",
      [:static, "test"]
    ]).should.equal 'VAR = BUFFER; foo = BUFFER; foo << (S:test); foo; VAR'
  end

  it 'should compile capture with multi' do
    gen = SimpleGenerator.new(:buffer => "VAR", :capture_generator => SimpleGenerator)
    gen.call([:multi,
      [:static, "before"],

      [:capture, "foo", [:multi,
        [:static, "static"],
        [:dynamic, "dynamic"],
        [:code, "code"]]],

      [:static, "after"]
    ]).should.equal 'VAR = BUFFER; VAR << (S:before); foo = BUFFER; foo << (S:static); ' +
      'foo << (D:dynamic); C:code; foo; VAR << (S:after); VAR'
  end

  it 'should compile newlines' do
    gen = SimpleGenerator.new(:buffer => "VAR")
    gen.call([:multi,
      [:static, "static"],
      [:newline],
      [:dynamic, "dynamic"],
      [:newline],
      [:code, "code"]
    ]).should.equal "VAR = BUFFER; VAR << (S:static); \n; " +
      "VAR << (D:dynamic); \n; C:code; VAR"
  end
end

describe Temple::Generators::Array do
  it 'should compile simple expressions' do
    gen = Temple::Generators::Array.new
    gen.call([:static,  'test']).should.equal '_buf = []; _buf << ("test"); _buf'
    gen.call([:dynamic, 'test']).should.equal '_buf = []; _buf << (test); _buf'
    gen.call([:code,    'test']).should.equal '_buf = []; test; _buf'
  end
end

describe Temple::Generators::ArrayBuffer do
  it 'should compile simple expressions' do
    gen = Temple::Generators::ArrayBuffer.new
    gen.call([:static,  'test']).should.equal '_buf = []; _buf << ("test"); _buf = _buf.join'
    gen.call([:dynamic, 'test']).should.equal '_buf = []; _buf << (test); _buf = _buf.join'
    gen.call([:code,    'test']).should.equal '_buf = []; test; _buf = _buf.join'
  end
end

describe Temple::Generators::StringBuffer do
  it 'should compile simple expressions' do
    gen = Temple::Generators::StringBuffer.new
    gen.call([:static,  'test']).should.equal '_buf = \'\'; _buf << ("test"); _buf'
    gen.call([:dynamic, 'test']).should.equal '_buf = \'\'; _buf << ((test).to_s); _buf'
    gen.call([:code,    'test']).should.equal '_buf = \'\'; test; _buf'
  end
end

describe Temple::Generators::RailsOutputBuffer do
  it 'should compile simple expressions' do
    gen = Temple::Generators::RailsOutputBuffer.new
    gen.call([:static,  'test']).should.equal '@output_buffer = ActiveSupport::SafeBuffer.new; ' +
      '@output_buffer.safe_concat(("test")); @output_buffer'
    gen.call([:dynamic, 'test']).should.equal '@output_buffer = ActiveSupport::SafeBuffer.new; ' +
      '@output_buffer.safe_concat(((test).to_s)); @output_buffer'
    gen.call([:code,    'test']).should.equal '@output_buffer = ActiveSupport::SafeBuffer.new; ' +
      'test; @output_buffer'
  end
end
