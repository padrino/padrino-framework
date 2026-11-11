require 'json'

module Padrino
  module Helpers
    ###
    # Helpers related to producing assets (images, stylesheets, js, etc) within templates.
    #
    module AssetTagHelpers
      APPEND_ASSET_EXTENSIONS = %w[js css]
      ABSOLUTE_URL_PATTERN = %r{\A(https?://)}
      ASSET_FOLDERS = {
        js: 'javascripts',
        css: 'stylesheets'
      }
      PRELOAD_DESTINATIONS = { 'js' => 'script', 'mjs' => 'module', 'css' => 'style', 'vtt' => 'track' }
                             .merge(%w[otf ttf woff woff2].to_h { |extension| [extension, 'font'] })
                             .merge(%w[avif gif ico jpeg jpg png svg webp].to_h { |extension| [extension, 'image'] })
                             .freeze
      PRELOAD_ASSET_KINDS = { 'script' => :js, 'module' => :js, 'style' => :css, 'image' => :images }.freeze
      JSON_ESCAPE = { '<' => '\u003c', '>' => '\u003e', '&' => '\u0026', "\u2028" => '\u2028', "\u2029" => '\u2029' }.freeze
      private_constant :PRELOAD_DESTINATIONS, :PRELOAD_ASSET_KINDS, :JSON_ESCAPE

      ##
      # Creates a div to display the flash of given type if it exists.
      #
      # @param [Symbol] kind
      #   The type of flash to display in the tag.
      # @param [Hash] options
      #   The html options for this section.
      #   use +bootstrap: true+ to support Twitter's bootstrap dismiss alert button.
      #
      # @return [String] Flash tag html with specified +options+.
      #
      # @example
      #   flash_tag(:notice, id: 'flash-notice')
      #   # Generates: <div class="notice" id="flash-notice">flash-notice</div>
      #   flash_tag(:error, :success)
      #   # Generates: <div class="error">flash-error</div>
      #   # <div class="success">flash-success</div>
      #
      def flash_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        bootstrap = options.delete(:bootstrap) if options[:bootstrap]
        args.inject(SafeBuffer.new) do |html, kind|
          next html unless flash[kind]
          flash_text = SafeBuffer.new << flash[kind]
          flash_text << content_tag(:button, '&times;'.html_safe, { type: :button, class: :close, 'data-dismiss': :alert }) if bootstrap
          html << content_tag(:div, flash_text, { class: kind }.update(options))
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
      #   link_to('click me', '/dashboard', class: 'linky')
      #   # Generates <a class="linky" href="/dashboard">click me</a>
      #
      #   link_to('click me', '/dashboard', remote: true)
      #   # Generates <a href="/dashboard" data-remote="true">click me</a>
      #
      #   link_to('click me', '/dashboard', method: :delete)
      #   # Generates <a href="/dashboard" data-method="delete" rel="nofollow">click me</a>
      #
      #   link_to('/dashboard', class: 'blocky') { 'click me' }
      #   # Generates <a class="blocky" href="/dashboard">click me</a>
      #
      # Note that you can pass :+if+ or :+unless+ conditions, but if you provide :current as
      # condition padrino return true/false if the request.path_info match the given url.
      #
      def link_to(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name = block_given? ? '' : args.shift
        href = args.first
        options = { href: href ? escape_link(href) : '#' }.update(options)
        options[:href] = escape_link(options[:href]) if options[:href]
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
      #   feed_tag :atom, url(:blog, :posts, format: :atom), title: "ATOM"
      #   # Generates: <link type="application/atom+xml" rel="alternate" href="/blog/posts.atom" title="ATOM" />
      #   feed_tag :rss, url(:blog, :posts, format: :rss)
      #   # Generates: <link type="application/rss+xml" rel="alternate" href="/blog/posts.rss" title="rss" />
      #
      def feed_tag(mime, url, options = {})
        full_mime = mime == :atom ? 'application/atom+xml' : 'application/rss+xml'
        tag(:link, { rel: 'alternate', type: full_mime, title: mime, href: url }.update(options))
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
      def mail_to(email, caption = nil, mail_options = {})
        mail_options, html_options = mail_options.partition { |key, _| %i[cc bcc subject body].include?(key) }
        mail_query = Rack::Utils.build_query(Hash[mail_options]).gsub(/\+/, '%20').gsub('%40', '@')
        mail_href = "mailto:#{email}"
        mail_href << "?#{mail_query}" unless mail_query.empty?
        link_to(caption || email, mail_href, Hash[html_options])
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
      #   meta_tag 'weblog,news', name: 'keywords'
      #   # Generates: <meta name="keywords" content="weblog,news" />
      #
      #   meta_tag 'text/html; charset=UTF-8', 'http-equiv' => 'Content-Type'
      #   # Generates: <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      #
      def meta_tag(content, options = {})
        options = { 'content' => content }.update(options)
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
      #   favicon_tag 'favicon.png', type: 'image/ico'
      #
      def favicon_tag(source, options = {})
        type = File.extname(source).sub('.', '')
        options = { href: image_path(source), rel: 'icon', type: "image/#{type}" }.update(options)
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
      def image_tag(url, options = {})
        options = { src: image_path(url) }.update(options)
        options[:alt] ||= image_alt(url) unless url.to_s =~ /\A(?:cid|data):|\A\Z/
        tag(:img, options)
      end

      ##
      # Returns a string suitable for an alt attribute of img element.
      #
      # @param [String] src
      #   The source path for the image tag.
      # @return [String] The alt attribute value.
      #
      def image_alt(src)
        File.basename(src, '.*').sub(/-[[:xdigit:]]{32,64}\z/, '').tr('-_', ' ').capitalize
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
        options = { rel: 'stylesheet' }.update(sources.last.is_a?(Hash) ? Utils.symbolize_keys(sources.pop) : {})
        sources.flatten.inject(SafeBuffer.new) do |all, source|
          all << tag(:link, { href: asset_path(:css, source) }.update(options))
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
      #   javascript_include_tag 'application', type: 'module'
      #
      def javascript_include_tag(*sources)
        options = sources.last.is_a?(Hash) ? Utils.symbolize_keys(sources.pop) : {}
        sources.flatten.inject(SafeBuffer.new) do |all, source|
          all << content_tag(:script, nil, { src: asset_path(:js, source) }.update(options))
        end
      end

      ##
      # Returns an import map script tag, which maps the module names that scripts import to the files
      # that hold them, then a module script tag that imports +entry+, if given.
      #
      # A relative source in +imports+ resolves in the javascripts folder like a +javascript_include_tag+
      # source, but without the asset stamp: a module the page imports both by its name and by a relative
      # path from another module is then one module, not two. Since the addresses carry no stamp, serve
      # the javascripts folder with revalidation (no long-lived immutable Cache-Control), so browsers pick
      # up changed modules after a deploy. A name ending in "/" maps a prefix ('lib/' => 'lib' maps
      # "lib/chart" to /javascripts/lib/chart). A source with a scheme (https:, data:), or starting with
      # "/" or "//", is written as given, with spaces escaped.
      #
      # @overload javascript_importmap_tag(entry = nil, options = {})
      #   @param [String] entry
      #     The module to import from the page, usually a name in +imports+. A blank one imports nothing.
      #   @param [Hash] options
      #     The html options for the import map tag. A +nonce+ goes on every tag this writes, for a
      #     Content Security Policy; +type+ is ignored.
      #   @option options [Hash] :imports
      #     The module names, each with the javascript source or URL it maps to (a blank one raises
      #     ArgumentError).
      #   @option options [Hash] :scopes
      #     Written as the import map's "scopes", as given; nil leaves it out.
      #   @option options [Hash] :integrity
      #     Written as the import map's "integrity" (URLs to their integrity metadata), as given; nil leaves it out.
      #   @option options [Boolean] :preload
      #     If true, a modulepreload link is written for each import (but not for prefixes), so browsers
      #     fetch them all at once instead of one import at a time.
      #
      # @return [String] Import map, modulepreload and module script html tags.
      #
      # @example
      #   javascript_importmap_tag 'application', imports: {
      #     'application' => 'application',
      #     '@hotwired/stimulus' => 'https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm'
      #   }
      #   # Generates: <script type="importmap">{"imports":{"application":"/javascripts/application.js",
      #   #   "@hotwired/stimulus":"https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"}}</script>
      #   #   <script type="module">import "application"</script>
      #
      #   javascript_importmap_tag imports: { 'app' => 'app', 'lodash/' => '/vendor/lodash/' }, preload: true
      #   # Generates: <script type="importmap">{"imports":{"app":"/javascripts/app.js","lodash/":"/vendor/lodash/"}}</script>
      #   #   <link rel="modulepreload" href="/javascripts/app.js" />
      #
      def javascript_importmap_tag(entry = nil, options = {})
        entry, options = nil, entry.merge(options) if entry.is_a?(Hash)
        options = Utils.symbolize_keys(options)
        imports = (options.delete(:imports) || {}).each_with_object({}) do |(name, source), all|
          all[name.to_s] = importmap_address(name.to_s, source)
        end
        importmap = { 'imports' => imports }
        %i[scopes integrity].each do |key|
          value = options.delete(key)
          importmap[key.to_s] = value if value
        end
        preload = options.delete(:preload)
        options.delete(:type)
        nonce = options[:nonce]
        html = SafeBuffer.new
        html << content_tag(:script, script_safe_json(importmap), { type: 'importmap' }.update(options))
        if preload
          imports.values.uniq.each do |href|
            html << tag(:link, rel: 'modulepreload', href: href, nonce: nonce) unless href.end_with?('/')
          end
        end
        unless entry.to_s.strip.empty?
          html << content_tag(:script, "import #{script_safe_json(entry.to_s)}".html_safe, type: 'module', nonce: nonce)
        end
        html
      end

      ##
      # Returns a link tag that tells browsers to fetch +source+ early, before the page asks for it.
      # Browsers only use a preload for a request to the same URL, so +source+ resolves the way the
      # page will ask for it. A relative script, module, stylesheet or image source resolves like
      # +javascript_include_tag+, +stylesheet_link_tag+ and +image_tag+ sources, asset stamp included;
      # pass an absolute path ('/images/hero.jpg') to preload an image a stylesheet's url() loads.
      # Any other relative source (a font a stylesheet refers to, a track, a file for fetch()) resolves
      # from the public folder without the asset stamp ('fonts/a.woff2' is /fonts/a.woff2). Preload
      # the modules an import map maps with +javascript_importmap_tag+'s +preload+ option, whose links
      # use the map's unstamped addresses.
      #
      # @param [String] source
      #   The path or URL of the file to preload.
      # @param [Hash] options
      #   The html options for the link tag.
      # @option options [String, Symbol] :as
      #   What the file is for: +:script+, +:style+, +:font+, +:image+, +:track+, +:fetch+, or +:module+
      #   for a module script (written as +rel="modulepreload"+). Defaults from the extension:
      #   js, mjs (module), css, vtt, otf, ttf, woff, woff2, avif, gif, ico, jpeg, jpg, png, svg and webp;
      #   pass it for any other file, since browsers skip a preload without it.
      # @option options [String] :type
      #   The MIME type, so browsers skip a file they can't use.
      # @option options [String, Boolean] :crossorigin
      #   The CORS mode; +true+ writes "anonymous", +false+ leaves it out. Fonts, tracks and +:fetch+ default
      #   to "anonymous": browsers only use a preload fetched the way the page fetches the file, which for
      #   those is in CORS mode. A track preload is used only when its media element has
      #   crossorigin="anonymous" too.
      #
      # @return [String] Link tag html for +source+ with specified +options+.
      #
      # @example
      #   preload_link_tag 'application.css'
      #   # Generates: <link rel="preload" href="/stylesheets/application.css?1269008689" as="style" />
      #
      #   preload_link_tag 'fonts/inter.woff2', type: 'font/woff2'
      #   # Generates: <link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossorigin="anonymous" />
      #
      #   preload_link_tag 'application', as: :module
      #   # Generates: <link rel="modulepreload" href="/javascripts/application.js?1269008689" />
      #
      def preload_link_tag(source, options = {})
        options = Utils.symbolize_keys(options)
        as = (options.delete(:as) || '').to_s.strip.downcase
        as = PRELOAD_DESTINATIONS[File.extname(source.to_s.sub(/[?#].*/m, '')).downcase.delete('.')] if as.empty?
        crossorigin = options.delete(:crossorigin)
        crossorigin = 'anonymous' if crossorigin == true || (crossorigin.nil? && %w[fetch font track].include?(as))
        rel = as == 'module' ? 'modulepreload' : 'preload'
        kind = PRELOAD_ASSET_KINDS[as]
        href = kind ? asset_path(kind, source) : unstamped_asset_path(nil, source)
        defaults = { rel: rel, href: href, as: (as if rel == 'preload'), type: options.delete(:type), crossorigin: crossorigin }
        tag(:link, defaults.update(options))
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
        source = asset_normalize_extension(kind, source.to_s.gsub(' ', '%20'))
        return source if source =~ ABSOLUTE_URL_PATTERN || source =~ %r{\A/}
        source = File.join(asset_folder_name(kind), source)
        timestamp = asset_timestamp(source)
        result_path = uri_root_path(source)
        "#{result_path}#{timestamp}"
      end

      private

      ##
      # Returns +value+ as JSON that can't end or change the script element it's written in.
      #
      def script_safe_json(value)
        JSON.generate(value).gsub(/[<>&\u2028\u2029]/, JSON_ESCAPE).html_safe
      end

      ##
      # Returns the import map address for the import +name+: its +source+ without the asset stamp,
      # ending in "/" for a prefix (a +name+ ending in "/").
      #
      def importmap_address(name, source)
        raise ArgumentError, "import #{name.inspect} has no source" if source.to_s.strip.empty?

        source = source.to_s
        source = "#{source}/" if name.end_with?('/') && !source.end_with?('/')
        unstamped_asset_path(:js, source)
      end

      ##
      # Returns the path to +source+ like +asset_path+, but without the asset stamp. A source with
      # a scheme or a leading "/" is kept, and one ending in "/" gets no extension.
      #
      def unstamped_asset_path(kind, source)
        source = source.to_s.gsub(' ', '%20')
        return source if source.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|/)}i)

        source = asset_normalize_extension(kind, source) unless source.end_with?('/')
        uri_root_path(asset_folder_name(kind), source)
      end

      ##
      # Returns the URI root of the application with optional paths appended.
      #
      # @example
      #   uri_root_path('/some/path') => "/root/some/path"
      #   uri_root_path('javascripts', 'test.js') => "/uri/root/javascripts/test.js"
      #
      def uri_root_path(*paths)
        root_uri = self.class.uri_root if self.class.respond_to?(:uri_root)
        File.join(ENV['RACK_BASE_URI'].to_s, root_uri || '/', *paths)
      end

      ##
      # Returns the timestamp mtime for an asset.
      #
      # @example
      #   asset_timestamp('some/path/to/file.png') => "?154543678"
      #
      def asset_timestamp(file_path)
        return nil if file_path =~ /\?/ || (self.class.respond_to?(:asset_stamp) && !self.class.asset_stamp)
        public_path = self.class.public_folder if self.class.respond_to?(:public_folder)
        public_path ||= Padrino.root('public') if Padrino.respond_to?(:root)
        public_file_path = File.join(public_path, file_path) if public_path
        unless public_file_path && File.exist?(public_file_path)
          shared_path = self.class.shared_public_folder if self.class.respond_to?(:shared_public_folder)
          public_file_path = File.join(shared_path, file_path) if shared_path
        end
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
      #    asset_normalize_extension(:images, '/foo/bar/baz.png') => "/foo/bar/baz.png"
      #    asset_normalize_extension(:js, '/foo/bar/baz') => "/foo/bar/baz.js"
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
      #   parse_conditions("/some/url", if: false) => true
      #
      def parse_conditions(url, options)
        if options.key?(:if)
          condition = options.delete(:if)
          condition == :current ? url == request.path_info : condition
        elsif (condition = options.delete(:unless))
          condition == :current ? url != request.path_info : !condition
        else
          true
        end
      end
    end
  end
end
