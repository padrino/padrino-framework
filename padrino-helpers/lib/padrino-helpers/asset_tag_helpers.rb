module Padrino
  module Helpers
    ###
    # Helpers related to producing assets (images, stylesheets, js, etc) within templates.
    #
    module AssetTagHelpers
      APPEND_ASSET_EXTENSIONS = ["js", "css"]
      ABSOLUTE_URL_PATTERN = %r{^(https?://)}
      ASSET_FOLDERS = {
        :js => 'javascripts',
        :css => 'stylesheets',
      }

      ##
      # Creates a div to display the flash of given type if it exists.
      #
      # @param [Symbol] kind
      #   The type of flash to display in the tag.
      # @param [Hash] options
      #   The html options for this section.
      #   use :bootstrap => true to support Twitter's bootstrap dismiss alert button.
      #
      # @return [String] Flash tag html with specified +options+.
      #
      # @example
      #   flash_tag(:notice, :id => 'flash-notice')
      #   # Generates: <div class="notice" id="flash-notice">flash-notice</div>
      #   flash_tag(:error, :success)
      #   # Generates: <div class="error">flash-error</div>
      #   # <div class="success">flash-success</div>
      #
      def flash_tag(*args)
        options = args.extract_options!
        bootstrap = options.delete(:bootstrap) if options[:bootstrap]
        args.inject(ActiveSupport::SafeBuffer.new) do |html,kind|
          flash_text = ActiveSupport::SafeBuffer.new << flash[kind]
          next html if flash_text.blank?
          flash_text << content_tag(:button, '&times;'.html_safe, {:type => :button, :class => :close, :'data-dismiss' => :alert}) if bootstrap
          html << content_tag(:div, flash_text, { :class => kind }.update(options))
        end
      end

      ##
      # Creates a link element with given name, url and options.
      #
      # @overload link_to(caption, url, options={})
      #   @param [String]  caption  The text caption.
      #   @param [String]  url      The url href.
      #   @param [Hash]    options  The html options.
      # @overload link_to(url, options={}, &block)
      #   @param [String]  url      The url href.
      #   @param [Hash]    options  The html options.
      #   @param [Proc]    block    The link content.
      #
      # @option options [Boolean] :if
      #   If true, the link will appear, otherwise not.
      # @option options [Boolean] :unless
      #   If false, the link will appear, otherwise not.
      # @option options [Boolean] :remote
      #   If true, this link should be handled by an ajax ujs handler.
      # @option options [String] :confirm
      #   Instructs ujs handler to alert confirm message.
      # @option options [Symbol] :method
      #   Instructs ujs handler to use different http method (i.e :post, :delete).
      #
      # @return [String] Link tag html with specified +options+.
      #
      # @example
      #   link_to('click me', '/dashboard', :class => 'linky')
      #   # Generates <a class="linky" href="/dashboard">click me</a>
      #
      #   link_to('click me', '/dashboard', :remote => true)
      #   # Generates <a href="/dashboard" data-remote="true">click me</a>
      #
      #   link_to('click me', '/dashboard', :method => :delete)
      #   # Generates <a href="/dashboard" data-method="delete" rel="nofollow">click me</a>
      #
      #   link_to('click me', :class => 'blocky') do; end
      #   # Generates <a class="blocky" href="#">click me</a>
      #
      # Note that you can pass :+if+ or :+unless+ conditions, but if you provide :current as
      # condition padrino return true/false if the request.path_info match the given url.
      #
      def link_to(*args, &block)
        options  = args.extract_options!
        name = block_given? ? '' : args.shift
        href = args.first
        options.reverse_merge!(:href => href || '#')
        return name unless parse_conditions(href, options)
        block_given? ? content_tag(:a, options, &block) : content_tag(:a, name, options)
      end

      ##
      # Creates a link tag that browsers and news readers can use to auto-detect an RSS or ATOM feed.
      #
      # @param [Symbol] mime
      #   The mime type of the feed (i.e :atom or :rss).
      # @param [String] url
      #   The url for the feed tag to reference.
      # @param[Hash] options
      #   The options for the feed tag.
      # @option options [String] :rel ("alternate")
      #   Specify the relation of this link.
      # @option options [String] :type
      #   Override the auto-generated mime type.
      # @option options [String] :title
      #   Specify the title of the link, defaults to the type.
      #
      # @return [String] Feed link html tag with specified +options+.
      #
      # @example
      #   feed_tag :atom, url(:blog, :posts, :format => :atom), :title => "ATOM"
      #   # Generates: <link type="application/atom+xml" rel="alternate" href="/blog/posts.atom" title="ATOM" />
      #   feed_tag :rss, url(:blog, :posts, :format => :rss)
      #   # Generates: <link type="application/rss+xml" rel="alternate" href="/blog/posts.rss" title="rss" />
      #
      def feed_tag(mime, url, options={})
        full_mime = (mime == :atom) ? 'application/atom+xml' : 'application/rss+xml'
        tag(:link, options.reverse_merge(:rel => 'alternate', :type => full_mime, :title => mime, :href => url))
      end

      ##
      # Creates a mail link element with given name and caption.
      #
      # @param [String] email
      #   The email address for the link.
      # @param [String] caption
      #   The caption for the link.
      # @param [Hash] mail_options
      #   The options for the mail link. Accepts html options.
      # @option mail_options [String] cc      The cc recipients.
      # @option mail_options [String] bcc     The bcc recipients.
      # @option mail_options [String] subject The subject line.
      # @option mail_options [String] body    The email body.
      #
      # @return [String] Mail link html tag with specified +options+.
      #
      # @example
      #   mail_to "me@demo.com"
      #   # Generates: <a href="mailto:me@demo.com">me@demo.com</a>
      #
      #   mail_to "me@demo.com", "My Email"
      #   # Generates: <a href="mailto:me@demo.com">My Email</a>
      #
      def mail_to(email, caption=nil, mail_options={})
        html_options = mail_options.slice!(:cc, :bcc, :subject, :body)
        mail_query = Rack::Utils.build_query(mail_options).gsub(/\+/, '%20').gsub('%40', '@')
        mail_href = "mailto:#{email}"; mail_href << "?#{mail_query}" if mail_query.present?
        link_to((caption || email), mail_href, html_options)
      end

      ##
      # Creates a meta element with the content and given options.
      #
      # @param [String] content
      #   The content for the meta tag.
      # @param [Hash] options
      #   The html options for the meta tag.
      #
      # @return [String] Meta html tag with specified +options+.
      #
      # @example
      #   meta_tag "weblog,news", :name => "keywords"
      #   # Generates: <meta name="keywords" content="weblog,news" />
      #
      #   meta_tag "text/html; charset=UTF-8", 'http-equiv' => "Content-Type"
      #   # Generates: <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      #
      def meta_tag(content, options={})
        options.reverse_merge!("content" => content)
        tag(:meta, options)
      end

      ##
      # Generates a favicon link. Looks inside images folder
      #
      # @param [String] source
      #   The source image path for the favicon link tag.
      # @param [Hash] options
      #   The html options for the favicon link tag.
      #
      # @return [String] The favicon link html tag with specified +options+.
      #
      # @example
      #   favicon_tag 'favicon.png'
      #   favicon_tag 'icons/favicon.png'
      #   # or override some options
      #   favicon_tag 'favicon.png', :type => 'image/ico'
      #
      def favicon_tag(source, options={})
        type = File.extname(source).sub('.','')
        options = options.dup.reverse_merge!(:href => image_path(source), :rel => 'icon', :type => "image/#{type}")
        tag(:link, options)
      end

      ##
      # Creates an image element with given url and options.
      #
      # @param [String] url
      #   The source path for the image tag.
      # @param [Hash] options
      #   The html options for the image tag.
      #
      # @return [String] Image html tag with +url+ and specified +options+.
      #
      # @example
      #   image_tag('icons/avatar.png')
      #
      def image_tag(url, options={})
        options.reverse_merge!(:src => image_path(url))
        tag(:img, options)
      end

      ##
      # Returns a html link tag for each of the sources provided.
      # You can pass in the filename without extension or a symbol and we search it in your +appname.public_folder+
      # like app/public/stylesheets for inclusion. You can provide also a full path.
      #
      # @overload stylesheet_link_tag(*sources, options={})
      #   @param [Array<String>] sources   Splat of css source paths
      #   @param [Hash]          options   The html options for the link tag
      #
      # @return [String] Stylesheet link html tag for +sources+ with specified +options+.
      #
      # @example
      #   stylesheet_link_tag 'style', 'application', 'layout'
      #
      # @api public.
      def stylesheet_link_tag(*sources)
        options = {
          :rel => 'stylesheet',
          :type => 'text/css'
        }.update(sources.extract_options!.symbolize_keys)
        sources.flatten.inject(ActiveSupport::SafeBuffer.new) do |all,source|
          all << tag(:link, { :href => asset_path(:css, source) }.update(options))
        end
      end

      ##
      # Returns a html script tag for each of the sources provided.
      # You can pass in the filename without extension or a symbol and we search it in your +appname.public_folder+
      # like app/public/javascript for inclusion. You can provide also a full path.
      #
      # @overload javascript_include_tag(*sources, options={})
      #   @param [Array<String>] sources   Splat of js source paths
      #   @param [Hash]          options   The html options for the script tag
      #
      # @return [String] Script tag for +sources+ with specified +options+.
      #
      # @example
      #   javascript_include_tag 'application', :extjs
      #
      def javascript_include_tag(*sources)
        options = {
          :type => 'text/javascript'
        }.update(sources.extract_options!.symbolize_keys)
        sources.flatten.inject(ActiveSupport::SafeBuffer.new) do |all,source|
          all << content_tag(:script, nil, { :src => asset_path(:js, source) }.update(options))
        end
      end

      ##
      # Returns the path to the image, either relative or absolute. We search it in your +appname.public_folder+
      # like app/public/images for inclusion. You can provide also a full path.
      #
      # @param [String] src
      #   The path to the image file (relative or absolute).
      #
      # @return [String] Path to an image given the +kind+ and +source+.
      #
      # @example
      #   # Generates: /images/foo.jpg?1269008689
      #   image_path("foo.jpg")
      #
      # @api public
      def image_path(src)
        asset_path(:images, src)
      end

      ##
      # Returns the path to the specified asset (css or javascript).
      #
      # @param [String] kind
      #   The kind of asset (i.e :images, :js, :css).
      # @param [String] source
      #   The path to the asset (relative or absolute).
      #
      # @return [String] Path for the asset given the +kind+ and +source+.
      #
      # @example
      #   # Generates: /javascripts/application.js?1269008689
      #   asset_path :js, :application
      #
      #   # Generates: /stylesheets/application.css?1269008689
      #   asset_path :css, :application
      #
      #   # Generates: /images/example.jpg?1269008689
      #   asset_path :images, 'example.jpg'
      #
      #   # Generates: /uploads/file.ext?1269008689
      #   asset_path 'uploads/file.ext'
      #
      def asset_path(kind, source = nil)
        kind, source = source, kind if source.nil?
        source = asset_normalize_extension(kind, URI.escape(source.to_s))
        return source if source =~ ABSOLUTE_URL_PATTERN || source =~ /^\//
        source = File.join(asset_folder_name(kind), source)
        timestamp = asset_timestamp(source)
        result_path = uri_root_path(source)
        "#{result_path}#{timestamp}"
      end

      private

      ##
      # Returns the URI root of the application with optional paths appended.
      #
      # @example
      #   uri_root_path("/some/path") => "/root/some/path"
      #   uri_root_path("javascripts", "test.js") => "/uri/root/javascripts/test.js"
      #
      def uri_root_path(*paths)
        root_uri = self.class.uri_root if self.class.respond_to?(:uri_root)
        File.join(ENV['RACK_BASE_URI'].to_s, root_uri || '/', *paths)
      end

      ##
      # Returns the timestamp mtime for an asset.
      #
      # @example
      #   asset_timestamp("some/path/to/file.png") => "?154543678"
      #
      def asset_timestamp(file_path)
        return nil if file_path =~ /\?/ || (self.class.respond_to?(:asset_stamp) && !self.class.asset_stamp)
        public_path = self.class.public_folder if self.class.respond_to?(:public_folder)
        public_path ||= Padrino.root("public") if Padrino.respond_to?(:root)
        public_file_path = File.join(public_path, file_path) if public_path
        stamp = File.mtime(public_file_path).to_i if public_file_path && File.exist?(public_file_path)
        stamp ||= Time.now.to_i
        "?#{stamp}"
      end

      ###
      # Returns the asset folder given a kind.
      #
      # Configureable by setting kind_asset_folder.
      #
      # @example
      #   asset_folder_name(:css) => 'stylesheets'
      #   asset_folder_name(:js)  => 'javascripts'
      #   asset_folder_name(:images) => 'images'
      #   asset_folder_name(:abrakadabrah) => 'abrakadabrah'
      #
      def asset_folder_name(kind)
        if self.class.respond_to? "#{kind}_asset_folder"
          self.class.send "#{kind}_asset_folder"
        else
          (ASSET_FOLDERS[kind] || kind).to_s
        end
      end

      ##
      # Normalizes the extension for a given asset.
      #
      #  @example
      #
      #    asset_normalize_extension(:images, "/foo/bar/baz.png") => "/foo/bar/baz.png"
      #    asset_normalize_extension(:js, "/foo/bar/baz") => "/foo/bar/baz.js"
      #
      def asset_normalize_extension(kind, source)
        ignore_extension = !APPEND_ASSET_EXTENSIONS.include?(kind.to_s)
        source << ".#{kind}" unless ignore_extension || source =~ /\.#{kind}/ || source =~ ABSOLUTE_URL_PATTERN
        source
      end

      ##
      # Parses link_to options for given correct conditions.
      #
      # @example
      #   parse_conditions("/some/url", :if => false) => true
      #
      def parse_conditions(url, options)
        if options.has_key?(:if)
          condition = options.delete(:if)
          condition == :current ? url == request.path_info : condition
        elsif condition = options.delete(:unless)
          condition == :current ? url != request.path_info : !condition
        else
          true
        end
      end
    end
  end
end
