module Padrino
  module Admin
    module Helpers
      # Set the title of the page.
      # 
      # An interesting thing wose that this helper 
      # try to translate itself to your current locale ex:
      # 
      #   # Look for: I18n.t("backend.titles.welcome_here", :default => "Welcome Here")
      #   title :welcome_here
      # 
      def title(title)
        title = I18n.t("admin.titles.#{title}", :default => title.to_s) if title.is_a?(Symbol)
        content_tag(:script, "Admin.app.setTitle(#{title.to_json})", :type => "text/javascript")
      end

      # This method work like error_message_for but use an Ext.Message.show({..})
      def show_messages_for(*objects)
        options = objects.extract_options!.symbolize_keys
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          options[:object_name] ||= objects.first.class

          I18n.with_options :locale => options[:locale], :scope => [:models, :errors, :template] do |locale|
            header_message = if options.include?(:header_message)
              escape_javascript(options[:header_message])
            else
              object_name = options[:object_name].to_s.gsub('_', ' ')
              object_name = I18n.t(object_name, :default => object_name, :scope => [:models], :count => 1)
              escape_javascript(locale.t :header, :count => count, :model => object_name)
            end
            message = escape_javascript(options.include?(:message) ? options[:message] : locale.t(:body))
            error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, escape_javascript(msg)) } }.join
            error_highlighter = objects.map {|object| object.errors_keys.map{ |k| "$('#{object.class.to_s.downcase}_#{k}').addClassName('x-form-invalid');" } }.join("\n")

            contents = ''
            contents << content_tag(:p, message) if message.present?
            contents << content_tag(:ul, error_messages, :class => :list)
            
            (<<-JAVASCRIPT).gsub(/ {14}/, '')
              Admin.app.unmask();
              Ext.Msg.show({
                title: '#{header_message}',
                msg: '<ul>#{contents}</ul>',
                buttons: Ext.Msg.OK,
                minWidth: 400 
              });
              #{error_highlighter}
            JAVASCRIPT
          end
        else
          (<<-JAVASCRIPT).gsub(/ {12}/, '')
            Admin.app.unmask();
            Ext.Msg.alert(Admin.locale.messages.compliments.title, Admin.locale.messages.compliments.message);
          JAVASCRIPT
        end
      end

      # This method add tab for in your view.
      # 
      # First argument is the name and title of the tab, an interesting thing wose that this helper 
      # try to translate itself to your current locale ex:
      # 
      #   # Look for: I18n.t("backend.tabs.settings", :default => "Settings")
      #   tab :settings do
      #     ...
      # 
      # The second argument specify if is necessary 10px of padding inside the tab, default is +true+
      # 
      # Third argument is an hash that accepts:
      # 
      # <tt>:id</tt>::    The id of the tab
      # <tt>:style</tt>:: Custom style of the tab
      # 
      def tab(name, padding=true, options={}, &block)
        options[:id]    ||= name.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/-+$/, '').gsub(/^-+$/, '')
        options[:style] ||= "padding:10px;#{options[:style]}" if padding
        options[:title]  = name.is_a?(Symbol) ? I18n.t("admin.tabs.#{name.to_s.downcase}", :default => name.to_s.humanize) : name
        options[:tabbed] = true
        options[:class]  = "x-hide-display"
        container = content_tag(:div, capture_html(&block), :class => :full) # Is necessary for IE6+
        concat_content content_tag(:div, container, options)
      end

      # This method generates a new ExtJs BoxComponent.
      # 
      #   Examples:
      # 
      #     -box "My Title", "My Subtitle", :submit => true, :collapsible => true, :style => "padding:none", :start => :close do
      #       my content
      # 
      # Defaults:
      # 
      # * :submit => false
      # * :collapsible => false
      # * :start => :close
      # 
      def box(title=nil, subtitle=nil, options={}, &block)
        title = I18n.t("admin.boxs.#{title.to_s.downcase}", :default => title.to_s.humanize) if title.is_a?(Symbol)
        options[:style] ||= "width:100%;"
        options[:start] ||= :open
        concat_content <<-HTML
          <div class="x-box" style="#{options[:style]}">
            <div class="x-box-tl">
              <div class="x-box-tr">
                <div class="x-box-tc">&nbsp;</div>
              </div>
            </div>
            <div class="x-box-ml">
              <div class="x-box-mr">
                <div class="x-box-mc">
                  <div id="x-body-title" style="#{"cursor:pointer" if options[:collapsible]}" onclick="#{"Backend.app.collapseBoxes(this);" if options[:collapsible]}">
                    #{"<h3 style=\"margin-bottom:0px;padding-bottom:0px;float:left;\">"+title+"</h3>" if title.present?}
                    #{"<div style=\"float:right\"><em>"+subtitle+"</em></div>" if subtitle.present?}
                    #{"<br class=\"clear\" />" if title.present? || subtitle.present?}
                    #{"<div style=\"font-size:0px\">&nbsp;</div>" if title.present? || subtitle.present?}
                  </div>
                  <div class="#{"x-box-collapsible" if options[:collapsible]}" style="width:99%;#{"display:none" if options[:collapsible] && options[:start] == :close}">
                    #{"<div style=\"font-size:10px\">&nbsp;</div>" if title.present? || subtitle.present?}
                    #{capture_html(&block)}
                    #{"<div style=\"text-align:right;margin-top:10px\">#{submit_tag(I18n.t("lipsiadmin.buttons.save"), :onclick=>"Backend.app.submitForm()")}</div>" if options[:submit]}
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
        HTML
      end

    end
  end
end