require 'helper'

describe Temple::HTML::AttributeMerger do
  before do
    @merger = Temple::HTML::AttributeMerger.new
  end

  it 'should pass static attributes through' do
    @merger.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:static, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:html, :attr, "class", [:static, "b"]]],
                     [:content]]
  end

  it 'should check for empty dynamic attribute' do
    @merger.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:dynamic, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:multi,
                       [:capture, "_temple_html_attributemerger1", [:dynamic, "b"]],
                       [:if, "!_temple_html_attributemerger1.empty?",
                        [:html, :attr, "class", [:dynamic, "_temple_html_attributemerger1"]]]]],
                     [:content]]
  end

  it 'should merge ids' do
    @merger.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'id', [:dynamic, 'a']], [:html, :attr, 'id', [:dynamic, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:multi,
                       [:capture, "_temple_html_attributemerger2",
                        [:multi, [:dynamic, "a"],
                         [:capture, "_temple_html_attributemerger1",
                          [:dynamic, "b"]],
                         [:if, "!_temple_html_attributemerger1.empty?",
                          [:multi, [:static, "_"],
                           [:dynamic, "_temple_html_attributemerger1"]]]]],
                       [:if, "!_temple_html_attributemerger2.empty?",
                        [:html, :attr, "id", [:dynamic, "_temple_html_attributemerger2"]]]]],
                     [:content]]
  end

  it 'should merge classes' do
    @merger.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:static, 'a']], [:html, :attr, 'class', [:dynamic, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:html, :attr, "class",
                       [:multi, [:static, "a"],
                        [:capture, "_temple_html_attributemerger1", [:dynamic, "b"]],
                        [:if, "!_temple_html_attributemerger1.empty?",
                         [:multi, [:static, " "],
                          [:dynamic, "_temple_html_attributemerger1"]]]]]],
                     [:content]]
  end
end

