module Padrino
  module Admin
    module Helpers
      module ViewHelpers
        ##
        # Set the title of the page.
        # 
        # An interesting thing wose that this helper 
        # try to translate itself to your current locale ex:
        # 
        # ==== Examples
        # 
        #   # Look for: I18n.t("admin.titles.welcome_here", :default => "Welcome Here")
        #   title :welcome_here
        #   # In this case we provide a +String+ so we don't try to translate them.
        #   title "This is my page title"
        # 
        def title(title)
          title = I18n.t("admin.titles.#{title}", :default => title.to_s) if title.is_a?(Symbol)
          tag(:span, :title => title)
        end

        ##
        # This method work like error_message_for but use an Ext.Message.show({..}).
        # 
        # It can return a list of errors like error_messages_for do but also (if no errors occours)
        # a great message box that indicate the success of the action.
        # 
        # ==== Options
        #
        # :url:: Used for change the <form.action>
        # :method:: Used for change the <form.method>
        # :header_tag:: Used for the header of the error div (default: "h2").
        # :id:: The id of the error div (default: "errorExplanation").
        # :class:: The class of the error div (default: "errorExplanation").
        # :object:: The object (or array of objects) for which to display errors,
        # if you need to escape the instance variable convention.
        # :object_name:: The object name to use in the header, or any text that you prefer.
        # If +:object_name+ is not set, the name of the first object will be used.
        # :header_message:: The message in the header of the error div.  Pass +nil+
        # or an empty string to avoid the header message altogether. (Default: "X errors
        # prohibited this object from being saved").
        # :message:: The explanation message after the header message and before
        # the error list.  Pass +nil+ or an empty string to avoid the explanation message
        # altogether. (Default: "There were problems with the following fields:").
        # 
        # ==== Examples
        # 
        #   # Show an window with errors or "congratulations" and point form.action to:
        #   # <form action="/admin/accounts/update/123.js" method="put">
        #   show_messages_for :account
        # 
        #   # Show an window with errors or "congratulations" and point form.action to:
        #   # <form action="/admin/accounts/create.js" method="create">
        #   show_messages_for :account, :url => url(:accounts_create), :method => :create
        # 
        def show_messages_for(object, options={})
          object          = object.is_a?(Symbol) ? instance_variable_get("@#{object}") : object
          count           = object.errors.count
          error_cleaner   = object.class.properties.map { |field|
            (<<-JAVASCRIPT).gsub(/ {12}/, '')
              parent.body.select('*[id=#{object.class.name.underscore}_#{field.name}]').each(function(field){
                field.removeClass('x-form-invalid');
              });
            JAVASCRIPT
          }.join("\n")

          unless count.zero?
            html = {}
            options[:object_name] ||= object.class

            I18n.with_options :locale => options[:locale], :scope => [:models, :errors, :template] do |locale|
              header_message = if options.include?(:header_message)
                escape_javascript(options[:header_message])
              else
                object_name = options[:object_name].to_s.gsub('_', ' ')
                object_name = I18n.t(object_name, :default => object_name, :scope => [:models], :count => 1)
                escape_javascript(locale.t :header, :count => count, :model => object_name)
              end
              message = escape_javascript(options.include?(:message) ? options[:message] : locale.t(:body))
              error_messages    = object.errors.full_messages.map { |msg| content_tag(:li, escape_javascript(msg)) }.join
              error_highlighter = object.errors_keys.map { |column|
                (<<-JAVASCRIPT).gsub(/ {16}/, '')
                  parent.body.select('*[id=#{object.class.name.underscore}_#{column}]').each(function(field){
                    field.addClass('x-form-invalid');
                  });
                JAVASCRIPT
              }.join("\n")
              contents = ''
              contents << content_tag(:p, message) if message.present?
              contents << content_tag(:ul, error_messages, :class => :list)

              (<<-JAVASCRIPT).gsub(/ {14}/, '')
                var parent = Ext.WindowMgr.getActive();
                #{error_cleaner}
                Ext.Msg.show({
                  title: '#{header_message}',
                  msg: '#{contents}',
                  buttons: Ext.Msg.OK,
                  minWidth: 400 
                });
                #{error_highlighter}
              JAVASCRIPT
            end
          else
            options[:url]     ||= url("#{object.class.name.underscore.pluralize}_update".to_sym, :id => object.id, :format => :js)
            options[:method]  ||= "put"
            (<<-JAVASCRIPT).gsub(/ {12}/, '')
              var parent  = Ext.WindowMgr.getActive();
              var form    = parent.body.select('form').first().dom;
              form.action = '#{options[:url]}';
              form.method = '#{options[:method]}';
              #{error_cleaner}
              Ext.Msg.alert(Admin.locale.messages.compliments.title, Admin.locale.messages.compliments.message);
            JAVASCRIPT
          end
        end

        ##
        # This method add tab for in your view.
        # 
        # First argument is the name and title of the tab, an interesting thing wose that this helper 
        # try to translate itself to your current locale ex:
        # 
        # === Examples
        # 
        #   # Look for: I18n.t("admin.tabs.settings", :default => "Settings")
        #   tab :settings do
        #     ...
        #   # In this case we provide a +String+ so we don't try to translate them.
        #   tab "This is my tab title"
        # 
        def tab(name, options={}, &block)
          options[:id]    ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/-+$/, '').gsub(/^-+$/, '')
          options[:style]  = "padding:10px;#{options[:style]}"
          options[:title]  = name.is_a?(Symbol) ? I18n.t("admin.tabs.#{name.to_s.downcase}", :default => name.to_s.humanize) : name
          options[:tabbed] = true
          options[:class]  = "x-hide-display"
          container = content_tag(:div, capture_html(&block), :class => :full) # Is necessary for IE6+
          concat_content content_tag(:div, container, options)
        end

        ##
        # This method generates a new ExtJs BoxComponent.
        # 
        # Our box can be collapsible so you can minimize them.
        # When you click on a box it will be expanded while others will be minimized (if all are collapsible)
        # 
        # ==== Options
        # 
        # :collapsible:: Indicate if the box can be minimized (clicking on the header). Default +false+
        # :start:: Indicate if the box on rendering is minimized or expanded. Can be: +open+ or +close+. Default +open+.
        # :style:: Stylesheet of the box container.
        # :class:: CSS Class of the box container.
        # 
        # ==== Examples
        # 
        #   # Create an expanded box that is not collapsible.
        #   -box "My Box 1", "My Subtitle" do
        #     my content
        # 
        #   # Create an expanded box that is collapsible.
        #   -box "My Box 2", "My Subtitle", :collapsible => true do
        #     my content
        # 
        #   # Create a minimized box that is collapsible.
        #   -box "My Box 3", "My Subtitle", :collapsible => true, :start => :close do
        #     my content
        # 
        # In this example when you click on "My Box 3", "My Box 2" will be minimized and nothing will happen on "My Box 1".
        # When you click on "My Box 2" it will be expanded and "My Box 3" will be minimized and nothing will happen on "My Box 1"
        # 
        # Also box title can be translated if you provide a +Symbol+ so if you create a box like:
        # 
        #   # Look for: I18n.t("admin.boxs.foo_bar", :default => "Foo Bar")
        #   -box :foo_bar do
        #     ...
        # 
        def box(title=nil, options={}, &block)
          title = I18n.t("admin.boxs.#{title}", :default => title.to_s.humanize) if title.is_a?(Symbol)
          subtitle = options.delete(:subtitle)
          options[:style] ||= "width:100%;"
          options[:start] ||= :open
          concat_content (<<-HTML).gsub(/ {10}/, '')
            <div class="#{options[:class]}" style="options[:style]">
              <div class="x-box">
                <div class="x-box-tl">
                  <div class="x-box-tr">
                    <div class="x-box-tc">&nbsp;</div>
                  </div>
                </div>
                <div class="x-box-ml">
                  <div class="x-box-mr">
                    <div class="x-box-mc">
                      <div id="x-body-title" style="#{"cursor:pointer" if options[:collapsible]}" onclick="#{"Admin.app.collapseBoxes(this);" if options[:collapsible]}">
                        #{"<h3 style=\"margin-bottom:0px;padding-bottom:0px;float:left;\">"+title+"</h3>" if title.present?}
                        #{"<div style=\"float:right\"><em>"+subtitle+"</em></div>" if subtitle.present?}
                        #{"<br class=\"clear\" />" if title.present? || subtitle.present?}
                        #{"<div style=\"font-size:0px\">&nbsp;</div>" if title.present? || subtitle.present?}
                      </div>
                      <div class="#{"x-box-collapsible" if options[:collapsible]}" style="width:99%;#{"display:none" if options[:collapsible] && options[:start] == :close}">
                        #{"<div style=\"font-size:10px\">&nbsp;</div>" if title.present? || subtitle.present?}
                        #{capture_html(&block)}
                      </div>
                    </div>
                  </div>
                </div>
                <div class="x-box-bl">
                  <div class="x-box-br">
                    <div class="x-box-bc">&nbsp;</div>
                  </div>
                </div>
              </div>
            </div>
          HTML
        end

        ##
        # Open a Standard window that can contain a grid. Works like a select_tag.
        # 
        # ==== Options
        # 
        # :with:: name of the association. Ex: :images.
        # :url:: the url of the gird, by default we autogenerate them using +:with+ ex: url(:images_index, :format => :js)
        # :controller:: the name of the controller that contains the gird, by default is +:with+
        # :show:: value to display, if it's a symbol we tranform them using +with+ ex: :name, will be: data["images.name"]
        # :get:: value to store in our db, Default: +:id+
        # :grid:: the name of the var of Admin.grid. Default :grid
        # :item:: the name of container. This necessary in cases where our grid it's in another container.
        # :update:: javascript function to handle when the user close grid with some selections. Default autogenerated.
        # :prompt:: text or html tag to prompt. Default is autogenerated.
        # :prompt_destroy:: text or html tag to prompt for clear current selections. Default is autogenerated.
        # :function:: name of the function. Default is autogenerated.
        # :multiple:: if true returns a collections of +:value+. Default false.
        # 
        # ==== Examples
        # 
        #   # Generate:
        #   # <script type="text/javascript">
        #   #   function showAccountImages(){
        #   #     Ext.Ajax.request({ 
        #   #       url: '/admin/images.js',
        #   #       scripts: false,
        #   #       success: function(response){
        #   #         try { eval(response.responseText) } catch(e) { Admin.app.error(e) };
        #   #         var win = new Admin.window({ grid: grid, width: 800, height: 600 });
        #   #         win.on('selected', function(win, selections){ ... });
        #   #         win.show();
        #   #       }
        #   #     });
        #   #   }
        #   # </script>
        #   # <ul id="account_images">
        #   #   <li>
        #   #     <span id="display">Foo</span>
        #   #     <input type="hidden" name="account[image_ids][]" value = "1" />
        #   #     <a href="#" onclick="this.up('li').destroy(); return false">Remove</a>
        #   #   </li>
        #   #   <li>
        #   #     <span id="display">Bar</span>
        #   #     <input type="hidden" name="account[image_ids][]" value = "2" />
        #   #     <a href="#" onclick="this.up('li').destroy(); return false">Remove</a>
        #   #   </li>
        #   # </ul>
        #   # <a href="#" onclick="showAccountImages(); return false">Show Images</a>
        #   open_grid :account, :image_ids, :with => :images, :show => :name, :get => :id, :multiple => true
        # 
        def open_window_grid(object_name, method, options={})

          # We need plural version of our association
          options[:controller] ||= options[:with]
          controller = options[:multiple] ? options[:controller] : "#{options[:controller].to_s.pluralize}".to_sym

          # Now we need our association
          association = instance_variable_get("@#{object_name}").send(options[:with])

          # Parsing not mandatory options
          options[:url]            ||= url("#{controller}_index".to_sym, :format => :js, :small => true)
          options[:grid]           ||= :grid
          options[:item]           ||= :undefined
          options[:get]            ||= :id
          options[:prompt]         ||= image_tag("admin/new.gif", :style => "vertical-align:bottom;padding:2px")
          options[:function]       ||= "show#{object_name.to_s.capitalize}#{options[:with].to_s.capitalize}"

          # Here we build our html template
          input_name  = "#{object_name}[#{method}]"
          input_name += "[]" if options[:multiple]

          # We need always some defaults values
          defaults = hidden_field_tag(input_name)

          # Now a reusable (also from extjs) template
          template = (<<-HTML).gsub(/ {10}/, "")
            <li>
              <span class="display">{0}</span>
              <input type="hidden" name="#{input_name}" value="{1}">
              <a href="#" onclick="this.up(\\'li\\').remove(); return false" class="closebutton">&nbsp;</a>
            </li>
          HTML

          # We create a collection of <li>
          collection = Array(association).map do |item| 
            template.gsub("{0}", item.send(options[:show]).to_s).
                     gsub("{1}", item.send(options[:get]).to_s)
          end

          # And we add our link for add new records
          li_link = content_tag(:li, link_to(options[:prompt], "#", :onclick => "#{options[:function]}(); return false;"), :class => :clean)
          collection << li_link

          # Now we have the final container
          container = content_tag(:ul, defaults + collection.join.gsub("\\",""), :id => "#{object_name}_#{method}", :class => "open-window-grid")

          # We need to refactor some values
          show   = "data['#{controller}.#{options[:show]}']" if options[:show].is_a?(Symbol)
          get    = options[:get].is_a?(Symbol) && options[:get] != :id ? "data['#{controller}.#{options[:get]}']" : options[:get]

          # Updater handler
          update_function = if options[:multiple]
            (<<-JAVASCRIPT).gsub(/ {12}/, "")
              var parent = win.parent.body.select("*[id=#{object_name}_#{method}]").first();
              Ext.each(selections, function(selection){
                var template = String.format('#{template.gsub(/\n/,"")}', selection.#{show}, selection.#{get});
                parent.insertHtml('afterBegin', template);
              });
            JAVASCRIPT
          else
            (<<-JAVASCRIPT).gsub(/ {12}/, "")
              var selection = selections.first();
              var template = String.format('#{template.gsub(/\n/,"")}', selection.#{show}, selection.#{get}) + '#{li_link}';
              win.parent.body.select("*[id=#{object_name}_#{method}]").first().update(template);
            JAVASCRIPT
          end

          # Now we build the update function (if not present)
          javascript = (<<-JAVASCRIPT).gsub(/ {10}/, '')
            function #{options[:function]}(){
              var me = Ext.WindowMgr.getActive();
              Ext.Ajax.request({ 
                url: '#{options[:url]}',
                scripts: false,
                success: function(response){
                  try { eval(response.responseText) } catch(e) { Admin.app.error(e) };
                  var win = new Admin.window({ grid: #{options[:grid]}, item: #{options[:item]}, width: 800, height:600, modal: true, parent:me });
                  win.on('selected', function(win, selections){
                    #{update_function}
                  });
                  win.show();
                }
              });
            }
          JAVASCRIPT

          # Now we return our html code
          [content_tag(:script, javascript, :type => 'text/javascript'), container, tag(:div, :class => :clear)].join("\n")
        end

        module AbstractFormBuilder #:nodoc:
          # f.open_window_grid :upload_ids, :brand_ids, :with => :brands, :get => :id, :show => :name
          def open_window_grid(field, options={})
            @template.open_window_grid object_name, field, options
          end
        end
      end # ViewHelpers
    end # Helpers
  end # Admin
end # Padrino