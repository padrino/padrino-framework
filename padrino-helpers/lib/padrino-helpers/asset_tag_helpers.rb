module Padrino
  module Helpers
    module AssetTagHelpers

      # Creates a div to display the flash of given type if it exists
      # flash_tag(:notice, :class => 'flash', :id => 'flash-notice')
      def flash_tag(kind, options={})
        flash_text = flash[kind]
        return '' if flash_text.blank?
        options.reverse_merge!(:class => 'flash')
        content_tag(:div, flash_text, options)
      end

      # Creates a link element with given name, url and options
      # link_to 'click me', '/dashboard', :class => 'linky'
      # link_to('/dashboard', :class => 'blocky') do ... end
      # parameters: name, url='javascript:void(0)', options={}, &block
      def link_to(*args, &block)
        options = args.extract_options!
        anchor  = options[:anchor] ? "##{CGI.escape options.delete(:anchor).to_s}" : ""
        if block_given?
          url = args[0] || 'javascript:void(0);'
          options.reverse_merge!(:href => url + anchor)
          link_content = capture_html(&block)
          result_link = content_tag(:a, link_content, options)
          block_is_template?(block) ? concat_content(result_link) : result_link
        else
          name, url = args[0], (args[1] || 'javascript:void(0);')
          options.reverse_merge!(:href => url + anchor)
          content_tag(:a, name, options)
        end
      end

      # Creates a mail link element with given name and caption
      # mail_to "me@demo.com"             => <a href="mailto:me@demo.com">me@demo.com</a>
      # mail_to "me@demo.com", "My Email" => <a href="mailto:me@demo.com">My Email</a>
      def mail_to(email, caption=nil, mail_options={})
        html_options = mail_options.slice!(:cc, :bcc, :subject, :body)
        mail_query = Rack::Utils.build_query(mail_options).gsub(/\+/, '%20').gsub('%40', '@')
        mail_href = "mailto:#{email}"; mail_href << "?#{mail_query}" if mail_query.present?
        link_to (caption || email), mail_href, html_options
      end

      # Creates a meta element with the content and given options
      # meta_tag "weblog,news", :name => "keywords"                         => <meta name="keywords" content="weblog,news">
      # meta_tag "text/html; charset=UTF-8", :http-equiv => "Content-Type"  => <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      def meta_tag(content, options={})
        options.reverse_merge!("content" => content)
        tag(:meta, options)
      end

      # Creates an image element with given url and options
      # image_tag('icons/avatar.png')
      def image_tag(url, options={})
        options.reverse_merge!(:src => image_path(url))
        tag(:img, options)
      end

      # Returns a stylesheet link tag for the sources specified as arguments
      # stylesheet_link_tag 'style', 'application', 'layout'
      def stylesheet_link_tag(*sources)
        options = sources.extract_options!.symbolize_keys
        sources.collect { |sheet| stylesheet_tag(sheet, options) }.join("\n")
      end

      # javascript_include_tag 'application', 'special'
      def javascript_include_tag(*sources)
        options = sources.extract_options!.symbolize_keys
        sources.collect { |script| javascript_tag(script, options) }.join("\n")
      end

      # Returns the path to the image, either relative or absolute
      def image_path(src)
        src.gsub!(/\s/, '')
        src =~ %r{^\s*(/|http)} ? src : uri_root_path('images', src)
      end

      protected

      # stylesheet_tag('style', :media => 'screen')
      def stylesheet_tag(source, options={})
        options = options.dup.reverse_merge!(:href => stylesheet_path(source), :media => 'screen', :rel => 'stylesheet', :type => 'text/css')
        tag(:link, options)
      end

      # javascript_tag 'application', :src => '/javascripts/base/application.js'
      def javascript_tag(source, options={})
        options = options.dup.reverse_merge!(:src => javascript_path(source), :type => 'text/javascript', :content => "")
        tag(:script, options)
      end

      # Returns the javascript_path appending the default javascripts path if necessary
      def javascript_path(source)
        return source if source =~ /^http/
        source.gsub!(/\.js$/, '')
        source_name = source; source_name << ".js" unless source =~ /\.js\w{2,4}$/
        result_path = source_name if source =~ %r{^/} # absolute path
        result_path ||= uri_root_path("javascripts", source_name)
        stamp = File.exist?(result_path) ? File.mtime(result_path) : Time.now.to_i
        "#{result_path}?#{stamp}"
      end

      # Returns the stylesheet_path appending the default stylesheets path if necessary
      def stylesheet_path(source)
        return source if source =~ /^http/
        source.gsub!(/\.css$/, '')
        source_name = source; source_name << ".css" unless source =~ /\.css$/
        result_path = source_name if source =~ %r{^/} # absolute path
        result_path ||= uri_root_path("stylesheets", source_name)
        stamp = File.exist?(result_path) ? File.mtime(result_path) : Time.now.to_i
        "#{result_path}?#{stamp}"
      end

      # Returns the uri root of the application, defaulting to '/'
      # @example uri_root('javascripts')
      def uri_root_path(*paths)
        root_uri = self.class.uri_root if self.class.respond_to?(:uri_root)
        File.join(root_uri || '/', *paths)
      end
    end
  end
end
