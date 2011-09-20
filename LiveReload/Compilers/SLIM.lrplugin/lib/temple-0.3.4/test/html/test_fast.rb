require 'helper'

describe Temple::HTML::Fast do
  before do
    @html = Temple::HTML::Fast.new
  end

  it 'should compile html doctype' do
    @html.call([:multi, [:html, :doctype, '5']]).should.equal [:multi, [:static, '<!DOCTYPE html>']]
    @html.call([:multi, [:html, :doctype, 'html']]).should.equal [:multi, [:static, '<!DOCTYPE html>']]
    @html.call([:multi, [:html, :doctype, '1.1']]).should.equal [:multi,
      [:static, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">']]
  end

  it 'should compile xml encoding' do
    @html.call([:html, :doctype, 'xml latin1']).should.equal [:static, "<?xml version='1.0' encoding='latin1' ?>"]
  end

  it 'should compile html comment' do
    @html.call([:html, :comment, [:static, 'test']]).should.equal [:multi, [:static, "<!--"], [:static, "test"], [:static, "-->"]]
  end

  it 'should compile autoclosed html tag' do
    @html.call([:html, :tag,
      'img', [:attrs],
      [:multi, [:newline]]
    ]).should.equal [:multi,
                     [:static, "<img"],
                     [:attrs],
                     [:static, " />"],
                     [:multi, [:newline]]]
  end

  it 'should compile explicitly closed html tag' do
    @html.call([:html, :tag,
      'closed', [:attrs]
    ]).should.equal [:multi,
                     [:static, "<closed"],
                     [:attrs],
                     [:static, " />"]]
  end

  it 'should compile html with content' do
    @html.call([:html, :tag,
      'div', [:attrs], [:content]
    ]).should.equal [:multi,
                     [:static, "<div"],
                     [:attrs],
                     [:static, ">"],
                     [:content],
                     [:static, "</div>"]]
  end

  it 'should compile html with attrs' do
    @html.call([:html, :tag,
      'div',
      [:html, :attrs,
       [:html, :attr, 'id', [:static, 'test']],
       [:html, :attr, 'class', [:dynamic, 'block']]],
       [:content]
    ]).should.equal [:multi,
                     [:static, "<div"],
                     [:multi,
                      [:multi, [:static, " id='"], [:static, "test"], [:static, "'"]],
                      [:multi, [:static, " class='"], [:dynamic, "block"], [:static, "'"]]],
                     [:static, ">"],
                     [:content],
                     [:static, "</div>"]]
  end

  it 'should keep codes intact' do
    exp = [:multi, [:code, 'foo']]
    @html.call(exp).should.equal exp
  end

  it 'should keep statics intact' do
    exp = [:multi, [:static, '<']]
    @html.call(exp).should.equal exp
  end

  it 'should keep dynamic intact' do
    exp = [:multi, [:dynamic, 'foo']]
    @html.call(exp).should.equal exp
  end
end
