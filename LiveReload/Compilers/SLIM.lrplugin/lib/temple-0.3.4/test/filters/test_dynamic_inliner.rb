require 'helper'

describe Temple::Filters::DynamicInliner do
  before do
    @filter = Temple::Filters::DynamicInliner.new
  end

  it 'should compile several statics into dynamic' do
    @filter.call([:multi,
      [:static, "Hello "],
      [:static, "World\n "],
      [:static, "Have a nice day"]
    ]).should.equal [:multi, [:dynamic, '"Hello World\n Have a nice day"']]
  end

  it 'should compile several dynamics into dynamic' do
    @filter.call([:multi,
      [:dynamic, "@hello"],
      [:dynamic, "@world"],
      [:dynamic, "@yeah"]
    ]).should.equal [:multi, [:dynamic, '"#{@hello}#{@world}#{@yeah}"']]
  end

  it 'should compile static and dynamic into dynamic' do
    @filter.call([:multi,
      [:static, "Hello"],
      [:dynamic, "@world"],
      [:dynamic, "@yeah"],
      [:static, "Nice"]
    ]).should.equal [:multi, [:dynamic, '"Hello#{@world}#{@yeah}Nice"']]
  end

  it 'should merge statics and dynamics around a code' do
    exp = @filter.call([:multi,
      [:static, "Hello "],
      [:dynamic, "@world"],
      [:code, "Oh yeah"],
      [:dynamic, "@yeah"],
      [:static, "Once more"]
    ]).should.equal [:multi,
      [:dynamic, '"Hello #{@world}"'],
      [:code, "Oh yeah"],
      [:dynamic, '"#{@yeah}Once more"']
    ]
  end

  it 'should keep codes intact' do
    exp = [:multi, [:code, 'foo']]
    @filter.call(exp).should.equal exp
  end

  it 'should keep single statics intact' do
    exp = [:multi, [:static, 'foo']]
    @filter.call(exp).should.equal exp
  end

  it 'should keep single dynamic intact' do
    exp = [:multi, [:dynamic, 'foo']]
    @filter.call(exp).should.equal exp
  end

  it 'should inline inside multi' do
    @filter.call([:multi,
      [:static, "Hello "],
      [:dynamic, "@world"],
      [:multi,
        [:static, "Hello "],
        [:dynamic, "@world"]],
      [:static, "Hello "],
      [:dynamic, "@world"]
    ]).should.equal [:multi,
      [:dynamic, '"Hello #{@world}"'],
      [:multi, [:dynamic, '"Hello #{@world}"']],
      [:dynamic, '"Hello #{@world}"']
    ]
  end

  it 'should merge across newlines' do
    exp = @filter.call([:multi,
      [:static, "Hello \n"],
      [:newline],
      [:dynamic, "@world"],
      [:newline]
    ]).should.equal [:multi,
      [:dynamic, ['"Hello \n"', '"#{@world}"', '""'].join("\\\n")]
    ]
  end

  it 'should compile static followed by newline' do
    @filter.call([:multi,
      [:static, "Hello \n"],
      [:newline],
      [:code, "world"]
    ]).should.equal [:multi,
      [:static, "Hello \n"],
      [:newline],
      [:code, "world"]
    ]
  end
end
