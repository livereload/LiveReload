require 'helper'
require 'erb'
require 'tilt'

describe Temple::ERB::Engine do
  it 'should compile erb' do
    src = %q{
%% hi
= hello
<% 3.times do |n| %>
* <%= n %>
<% end %>
}

    erb(src).should.equal ERB.new(src).result
  end

  it 'should recognize comments' do
    src = %q{
hello
  <%# comment -- ignored -- useful in testing %>
world}

    erb(src).should.equal ERB.new(src).result
  end

  it 'should recognize <%% and %%>' do
    src = %q{
<%%
<% if true %>
  %%>
<% end %>
}

    erb(src).should.equal "\n<%\n\n  %>\n\n" #ERB.new(src).result
  end

  it 'should escape automatically' do
    src = '<%= "<" %>'
    ans = '&lt;'
    erb(src, :auto_escape => true).should.equal ans
  end

  it 'should support == to disable automatic escape' do
    src = '<%== "<" %>'
    ans = '<'
    erb(src, :auto_escape => true).should.equal ans
  end

  it 'should support trim mode' do
    src = %q{
%% hi
= hello
<% 3.times do |n| %>
* <%= n %>
<% end %>
}

    erb(src, :trim_mode => '>').should.equal ERB.new(src, nil, '>').result
    erb(src, :trim_mode => '<>').should.equal ERB.new(src, nil, '<>').result
  end
end
