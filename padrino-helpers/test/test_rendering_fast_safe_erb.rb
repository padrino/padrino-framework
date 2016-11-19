require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'padrino/rendering/fast_safe_erb_template'

EXAMPLES = <<EOT

<<<< be adding LFs
%% hi
= hello
<% 3.times do |n| %>
% n=0
* <%= n %>
<% end %>
----
%% hi
= hello

% n=0
* 0

% n=0
* 1

% n=0
* 2

>>>>

<<<< be properly trimming <%- -%>
<% x = %w(hello world) -%>
NotSkip <%- y = x -%> NotSkip
<% x.each do |w| -%>
  <%- up = w.upcase -%>
  * <%= up %>
<% end -%>
 <%- z = nil -%> NotSkip <%- z = x %>
 <%- z.each do |w| -%>
   <%- down = w.downcase -%>
   * <%= down %>
   <%- up = w.upcase -%>
   * <%= up %>
 <%- end -%>
KeepNewLine <%- z = nil -%>\s
----
NotSkip  NotSkip
  * HELLO
  * WORLD
 NotSkip 
   * hello
   * HELLO
   * world
   * WORLD
KeepNewLine \s
>>>>

<<<< be escaping &'<>"
<table>
 <tbody>
  <%- i = 0
     ['&\\'<>"2'].each_with_index do |item, i| -%>
  <tr>
   <td><%= i+1 %></td>
   <td><%= item %></td>
  </tr>
 <%- end -%>
 </tbody>
</table>
<%== i+1 %>
----
<table>
 <tbody>
  <tr>
   <td>1</td>
   <td>&amp;&#039;&lt;&gt;&quot;2</td>
  </tr>
 </tbody>
</table>
1
>>>>

<<<< be carrying <%% %%> as <% %>
<table>
<%% for item in @items %%>
  <tr>
    <td><%# i+1 %></td>
    <td><%# item %></td>
  </tr>
  <%% end %>
</table>
----
<table>
<% for item in @items %>
  <tr>
    <td></td>
    <td></td>
  </tr>
  <% end %>
</table>
>>>>

<<<< be commenting
<% i = 0 -%>
<table>
  <% for item in [2] %>
  <tr>
    <td><%# 
    i+1
    %></td>
    <td><%== item %></td>
  </tr>
  <% end %><%#%>
  <% i %>a
  <% i %>
</table>
----
<table>
  
  <tr>
    <td></td>
    <td>2</td>
  </tr>
  
  a
  
</table>
>>>>

<<<< be not escaping html_safe
<table>
 <tbody>
  <%- i = 0
     ['<'].each_with_index do |item, i| -%>
  <tr>
   <td><%= item %></td>
   <td><%= item.html_safe %></td>
   <td><%== item %></td>
  </tr>
 <%- end -%>
 </tbody>
</table>
<%== i+1 %>
----
<table>
 <tbody>
  <tr>
   <td>&lt;</td>
   <td><</td>
   <td><</td>
  </tr>
 </tbody>
</table>
1
>>>>

EOT

describe "Padrino::Rendering::FastSafeErbTemplate" do
  EXAMPLES_REGEXP = /^<{4} (.*?)\n(.*?)\n-{4}\n(.*?)\n>{4}$/m

  EXAMPLES.scan(EXAMPLES_REGEXP).each do |(description, source, expected)|
    it "should #{description}\n#{source}\n" do
      template = Padrino::Rendering::FastSafeErbTemplate.new { source }
      assert_equal expected, template.render
    end
  end
end
