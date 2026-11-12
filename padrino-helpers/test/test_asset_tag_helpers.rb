require_relative 'helper'
require_relative 'fixtures/markup_app/app'

describe 'AssetTagHelpers' do
  include Padrino::Helpers::AssetTagHelpers

  def app
    MarkupDemo
  end

  def flash
    @_flash ||= { notice: 'Demo notice' }
  end

  describe 'for #flash_tag method' do
    it 'should display flash with no given attributes' do
      assert_html_has_tag(flash_tag(:notice), 'div.notice', content: 'Demo notice')
    end
    it 'should display flash with given attributes' do
      actual_html = flash_tag(:notice, class: 'notice', id: 'notice-area')
      assert_html_has_tag(actual_html, 'div.notice#notice-area', content: 'Demo notice')
    end
    it 'should display multiple flash tags with given attributes' do
      flash[:error] = 'wrong'
      flash[:success] = 'okey'
      actual_html = flash_tag(:success, :warning, :error, id: 'area')
      assert_html_has_tag(actual_html, 'div.success#area', content: flash[:success])
      assert_html_has_tag(actual_html, 'div.error#area', content: flash[:error])
      assert_html_has_no_tag(actual_html, 'div.warning')
    end
  end

  describe 'for #link_to method' do
    it 'should display link element with no given attributes' do
      assert_html_has_tag(link_to('Sign up', '/register'), 'a', content: 'Sign up', href: '/register')
    end

    it 'should display link element with given attributes' do
      actual_html = link_to('Sign up', '/register', class: 'first', id: 'linky')
      assert_html_has_tag(actual_html, 'a#linky.first', content: 'Sign up', href: '/register')
    end

    it 'should display link element with void url and options' do
      actual_link = link_to('Sign up', class: 'test')
      assert_html_has_tag(actual_link, 'a', content: 'Sign up', href: '#', class: 'test')
    end

    it 'should display link element with remote option' do
      actual_link = link_to('Sign up', '/register', remote: true)
      assert_html_has_tag(actual_link, 'a', content: 'Sign up', href: '/register', 'data-remote' => 'true')
    end

    it 'should display link element with method option' do
      actual_link = link_to('Sign up', '/register', method: :delete)
      assert_html_has_tag(actual_link, 'a', content: 'Sign up', href: '/register', 'data-method' => 'delete', rel: 'nofollow')
    end

    it 'should display link element with confirm option' do
      actual_link = link_to('Sign up', '/register', confirm: 'Are you sure?')
      assert_html_has_tag(actual_link, 'a', content: 'Sign up', href: '/register', 'data-confirm' => 'Are you sure?')
    end

    it 'should display link element with ruby block' do
      actual_link = link_to('/register', class: 'first', id: 'binky') { 'Sign up' }
      assert_html_has_tag(actual_link, 'a#binky.first', content: 'Sign up', href: '/register')
    end

    it 'should escape the link text' do
      actual_link = link_to('/register', class: 'first', id: 'binky') { '<&>' }
      assert_html_has_tag(actual_link, 'a#binky.first', href: '/register')
      assert_match '&lt;&amp;&gt;', actual_link
    end

    it 'should escape the link href' do
      actual_link = link_to('Sign up', '/register new%20user')
      assert_html_has_tag(actual_link, 'a', href: '/register%20new%20user')
    end

    it 'should reject javascript: URIs' do
      actual_link = link_to('click', 'javascript:alert(1)')
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should reject javascript: URIs with mixed case and whitespace' do
      actual_link = link_to('click', "JaVaScRiPt:\nalert(1)")
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should reject data: URIs' do
      actual_link = link_to('click', 'data:text/html,<script>alert(1)</script>')
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should reject vbscript: URIs' do
      actual_link = link_to('click', 'vbscript:MsgBox("xss")')
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should reject unsafe schemes passed via options hash' do
      actual_link = link_to('click', '/safe', href: 'javascript:alert(1)')
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should allow http and https URIs' do
      assert_match 'href="http://example.com"', link_to('click', 'http://example.com')
      assert_match 'href="https://example.com"', link_to('click', 'https://example.com')
    end

    it 'should allow mailto and tel URIs' do
      assert_match 'href="mailto:a@b.com"', link_to('email', 'mailto:a@b.com')
      assert_match 'href="tel:+1234567890"', link_to('call', 'tel:+1234567890')
    end

    it 'should allow relative paths and anchors' do
      assert_html_has_tag(link_to('click', '/path'), 'a', href: '/path')
      assert_match 'href="#anchor"', link_to('click', '#anchor')
      assert_match 'href="?query=1"', link_to('click', '?query=1')
    end

    it 'should allow relative paths with colons in the query or fragment' do
      assert_match 'href="search?q=a:b"', link_to('click', 'search?q=a:b')
      assert_match 'href="users/1?at=10:30"', link_to('click', 'users/1?at=10:30')
      assert_match 'href="page#x:y"', link_to('click', 'page#x:y')
    end

    it 'should reject unsafe URIs preceded by control characters' do
      actual_link = link_to('click', "\u0001 javascript:alert(1)")
      assert_html_has_tag(actual_link, 'a', href: '#', content: 'click')
    end

    it 'should reject unsafe URIs with tabs or newlines inside the scheme' do
      assert_html_has_tag(link_to('click', "java\tscript:alert(1)"), 'a', href: '#', content: 'click')
      assert_html_has_tag(link_to('click', "java\nscript:alert(1)"), 'a', href: '#', content: 'click')
    end

    it 'should not escape image_tag' do
      actual_link = link_to(image_tag('/my/fancy/image.png'), class: 'first', id: 'binky')
      assert_html_has_tag(actual_link, 'img', src: '/my/fancy/image.png')
    end

    it 'should render alt text by default' do
      actual_tag = image_tag('/my/fancy/image.png')
      assert_html_has_tag(actual_tag, 'img', src: '/my/fancy/image.png', alt: 'Image')
    end

    it 'should render humanized alt text' do
      actual_tag = image_tag('/my/fancy/image_white.png')
      assert_html_has_tag(actual_tag, 'img', src: '/my/fancy/image_white.png', alt: 'Image white')
    end

    it 'should remove hash value from src path' do
      actual_tag = image_tag('/my/fancy/sprite-47bce5c74f589f4867dbd57e9ca9f808.png')
      assert_html_has_tag(actual_tag, 'img', src: '/my/fancy/sprite-47bce5c74f589f4867dbd57e9ca9f808.png', alt: 'Sprite')
    end

    it 'should display link block element in haml' do
      get '/haml/link_to'
      assert_response_has_tag :a, content: 'Test 1 No Block', href: '/test1', class: 'test', id: 'test1'
      assert_response_has_tag :a, content: 'Test 2 With Block', href: '/test2', class: 'test', id: 'test2'
    end

    it 'should display link block element in erb' do
      get '/erb/link_to'
      assert_response_has_tag :a, content: 'Test 1 No Block', href: '/test1', class: 'test', id: 'test1'
      assert_response_has_tag :a, content: 'Test 2 With Block', href: '/test2', class: 'test', id: 'test2'
    end

    it 'should display link block element in slim' do
      get '/slim/link_to'
      assert_response_has_tag :a, content: 'Test 1 No Block', href: '/test1', class: 'test', id: 'test1'
      assert_response_has_tag :a, content: 'Test 2 With Block', href: '/test2', class: 'test', id: 'test2'
    end

    it 'should not double-escape' do
      actual_link = link_to('test escape', '?a=1&b=2')
      assert_html_has_tag(actual_link, 'a', href: '?a=1&b=2')
      assert_match(/&amp;/, actual_link)
      refute_match(/&amp;amp;/, actual_link)
    end

    it 'should escape scary things' do
      actual_link = link_to('test escape<adfs>', '?a=1&b=<script>alert(1)</script>')
      refute_match('<script', actual_link)
    end
  end

  describe 'for #mail_to method' do
    it 'should display link element for mail to no caption' do
      actual_html = mail_to('test@demo.com')
      assert_html_has_tag(actual_html, :a, href: 'mailto:test@demo.com', content: 'test@demo.com')
    end

    it 'should display link element for mail to with caption' do
      actual_html = mail_to('test@demo.com', 'My Email', class: 'demo')
      assert_html_has_tag(actual_html, :a, href: 'mailto:test@demo.com', content: 'My Email', class: 'demo')
    end

    it 'should display link element for mail to with caption and mail options' do
      actual_html = mail_to('test@demo.com', 'My Email', subject: 'demo test', class: 'demo', cc: 'foo@test.com')
      assert_html_has_tag(actual_html, :a, class: 'demo')
      assert_match(/mailto:test@demo.com\?/, actual_html)
      assert_match(/cc=foo@test\.com/, actual_html)
      assert_match(/subject=demo%20test/, actual_html)
    end

    it 'should escape & with encoded string and &amp; in HTML' do
      actual_html = mail_to('test@demo.com', 'My&Email', subject: 'this&that')
      assert_match 'this%26that', actual_html
      assert_match 'My&amp;Email', actual_html
    end

    it 'should not double-escape ampersands in query' do
      actual_html = mail_to('to@demo.com', 'Email', bcc: 'bcc@test.com', subject: 'Hi there')
      assert_html_has_tag(actual_html, :a, href: 'mailto:to@demo.com?bcc=bcc@test.com&subject=Hi%20there', content: 'Email')
      assert_match(/&amp;/, actual_html)
      refute_match(/&amp;amp;/, actual_html)
    end

    it 'should display mail link element in haml' do
      get '/haml/mail_to'
      assert_response_has_tag 'p.simple a', href: 'mailto:test@demo.com', content: 'test@demo.com'
      assert_response_has_tag 'p.captioned a', href: 'mailto:test@demo.com', content: 'Click my Email'
    end

    it 'should display mail link element in erb' do
      get '/erb/mail_to'
      assert_response_has_tag 'p.simple a', href: 'mailto:test@demo.com', content: 'test@demo.com'
      assert_response_has_tag 'p.captioned a', href: 'mailto:test@demo.com', content: 'Click my Email'
    end

    it 'should display mail link element in slim' do
      get '/slim/mail_to'
      assert_response_has_tag 'p.simple a', href: 'mailto:test@demo.com', content: 'test@demo.com'
      assert_response_has_tag 'p.captioned a', href: 'mailto:test@demo.com', content: 'Click my Email'
    end
  end

  describe 'for #meta_tag method' do
    it 'should display meta tag with given content and name' do
      actual_html = meta_tag('weblog,news', name: 'keywords')
      assert_html_has_tag(actual_html, 'meta', name: 'keywords', content: 'weblog,news')
    end

    it 'should display meta tag with given content and http-equiv' do
      actual_html = meta_tag('text/html; charset=UTF-8', "http-equiv": 'Content-Type')
      assert_html_has_tag(actual_html, 'meta', "http-equiv": 'Content-Type', content: 'text/html; charset=UTF-8')
    end

    it 'should display meta tag element in haml' do
      get '/haml/meta_tag'
      assert_response_has_tag 'meta', content: 'weblog,news', name: 'keywords'
      assert_response_has_tag 'meta', content: 'text/html; charset=UTF-8', "http-equiv": 'Content-Type'
    end

    it 'should display meta tag element in erb' do
      get '/erb/meta_tag'
      assert_response_has_tag 'meta', content: 'weblog,news', name: 'keywords'
      assert_response_has_tag 'meta', content: 'text/html; charset=UTF-8', "http-equiv": 'Content-Type'
    end

    it 'should display meta tag element in slim' do
      get '/slim/meta_tag'
      assert_response_has_tag 'meta', content: 'weblog,news', name: 'keywords'
      assert_response_has_tag 'meta', content: 'text/html; charset=UTF-8', "http-equiv": 'Content-Type'
    end
  end

  describe 'for #image_tag method' do
    it 'should display image tag absolute link with no options' do
      assert_html_has_tag(image_tag('/absolute/pic.gif'), 'img', src: '/absolute/pic.gif')
    end

    it 'should display image tag relative link with specified uri root' do
      time = stop_time_for_test
      self.class.stubs(:uri_root).returns('/blog')
      assert_html_has_tag(image_tag('relative/pic.gif'), 'img', src: "/blog/images/relative/pic.gif?#{time.to_i}")
    end

    it 'should display image tag relative link with options' do
      time = stop_time_for_test
      assert_html_has_tag(image_tag('relative/pic.gif', class: 'photo'), 'img.photo', src: "/images/relative/pic.gif?#{time.to_i}")
    end

    it 'should display image tag uri link with options' do
      assert_html_has_tag(image_tag('http://demo.org/pic.gif', class: 'photo'), 'img.photo', src: 'http://demo.org/pic.gif')
    end

    it 'should display image tag relative link with incorrect spacing' do
      time = stop_time_for_test
      assert_html_has_tag(image_tag(' relative/ pic.gif  ', class: 'photo'), 'img.photo', src: "/images/%20relative/%20pic.gif%20%20?#{time.to_i}")
    end

    it 'should not use a timestamp if stamp setting is false' do
      assert_html_has_tag(image_tag('/absolute/pic.gif'), 'img', src: '/absolute/pic.gif')
    end

    it 'should have xhtml convention tag' do
      assert_equal image_tag('/absolute/pic.gif'), '<img src="/absolute/pic.gif" alt="Pic" />'
    end

    it 'should resolve each source of a srcset hash like src' do
      time = stop_time_for_test
      self.class.stubs(:uri_root).returns('/blog')
      actual_html = image_tag('pic.jpg', srcset: { 'pic.jpg' => '1x', 'hd/pic@2x.jpg' => '2x' })
      srcset = "/blog/images/pic.jpg?#{time.to_i} 1x, /blog/images/hd/pic@2x.jpg?#{time.to_i} 2x"
      assert_equal %(<img src="/blog/images/pic.jpg?#{time.to_i}" srcset="#{srcset}" alt="Pic" />), actual_html
    end

    it 'should write a srcset array of pairs with sizes' do
      self.class.stubs(:asset_stamp).returns(false)
      actual_html = image_tag('small.jpg', srcset: [['small.jpg', '480w'], ['large.jpg', '1080w']], sizes: '(max-width: 600px) 480px, 1080px')
      expected = '<img src="/images/small.jpg" srcset="/images/small.jpg 480w, /images/large.jpg 1080w" ' \
                 'sizes="(max-width: 600px) 480px, 1080px" alt="Small" />'
      assert_equal expected, actual_html
    end

    it 'should keep absolute urls and paths in a srcset' do
      self.class.stubs(:asset_stamp).returns(false)
      actual_html = image_tag('pic.jpg', srcset: { '/static/pic.jpg' => '1x', 'https://cdn.example.com/pic@2x.jpg' => '2x' })
      assert_html_has_tag(actual_html, 'img', srcset: '/static/pic.jpg 1x, https://cdn.example.com/pic@2x.jpg 2x')
    end

    it 'should write a srcset string as given' do
      actual_html = image_tag('/pic.jpg', srcset: 'pic@2x.jpg 2x, pic&3x.jpg 3x')
      assert_equal '<img src="/pic.jpg" srcset="pic@2x.jpg 2x, pic&amp;3x.jpg 3x" alt="Pic" />', actual_html
    end

    it 'should escape the sources and descriptors of a srcset' do
      self.class.stubs(:asset_stamp).returns(false)
      actual_html = image_tag('/pic.jpg', srcset: { 'pic.jpg?w=1&h=2' => '2x', 'a"b.jpg' => '<3x>' })
      assert_includes actual_html, 'srcset="/images/pic.jpg?w=1&amp;h=2 2x, /images/a&quot;b.jpg &lt;3x&gt;"'
    end

    it 'should write the string candidates of a srcset array as given' do
      self.class.stubs(:asset_stamp).returns(false)
      actual_html = image_tag('/pic.jpg', srcset: ['pic.jpg 1x', ['pic@2x.jpg', '2x'], '/hd/pic.jpg 3x'])
      assert_html_has_tag(actual_html, 'img', srcset: 'pic.jpg 1x, /images/pic@2x.jpg 2x, /hd/pic.jpg 3x')
    end

    it 'should refuse a srcset array entry without a descriptor' do
      error = assert_raises(ArgumentError) { image_tag('pic.jpg', srcset: ['pic@2x.jpg', '2x']) }
      assert_includes error.message, '"pic@2x.jpg"'
      assert_includes error.message, "[['pic@2x.jpg', '2x']]"
      assert_raises(ArgumentError) { image_tag('pic.jpg', srcset: ['pic.jpg 1x', ' pic@2x.jpg ']) }
    end

    it 'should take string keys like symbol keys' do
      self.class.stubs(:asset_stamp).returns(false)
      options = { 'srcset' => { 'pic@2x.jpg' => '2x' }.freeze, 'alt' => 'A hill' }.freeze
      expected = '<img src="/images/pic.jpg" srcset="/images/pic@2x.jpg 2x" alt="A hill" />'
      assert_equal expected, image_tag('pic.jpg', options)
      assert_equal({ 'srcset' => { 'pic@2x.jpg' => '2x' }, 'alt' => 'A hill' }, options)
    end

    it 'should write no srcset for an empty hash or array' do
      assert_equal '<img src="/pic.jpg" alt="Pic" />', image_tag('/pic.jpg', srcset: {})
      assert_equal '<img src="/pic.jpg" alt="Pic" />', image_tag('/pic.jpg', srcset: [])
    end
  end

  describe 'for #picture_tag method' do
    before { self.class.stubs(:asset_stamp).returns(false) }

    it 'should write a source for each source but the last and an img for the last' do
      expected = '<picture><source srcset="/images/pic.webp" type="image/webp" />' \
                 '<img src="/images/pic.jpg" alt="Pic" /></picture>'
      assert_equal expected, picture_tag('pic.webp', 'pic.jpg')
    end

    it 'should infer the type of each source from its extension' do
      types = {
        'a.avif' => 'image/avif', 'a.webp' => 'image/webp', 'a.png' => 'image/png', 'a.gif' => 'image/gif',
        'a.svg' => 'image/svg+xml', 'a.jpeg' => 'image/jpeg', 'a.jpg' => 'image/jpeg', 'b.JPG' => 'image/jpeg',
        'https://cdn.example.com/c.webp?w=300&q=80' => 'image/webp', 'd.avif#frag' => 'image/avif'
      }
      actual_html = picture_tag(*types.keys, 'fallback.jpg')
      types.each do |source, type|
        assert_html_has_tag(actual_html, 'picture source', srcset: asset_path(:images, source), type: type)
      end
      assert_html_has_tag(actual_html, 'picture source', count: types.size)
    end

    it 'should refuse a source other than the last without a known image type' do
      ['pic.jxl', 'https://cdn.example.com/pic', 'https://img.example.com', 'pic.unknown', 'page.html'].each do |source|
        error = assert_raises(ArgumentError) { picture_tag(source, 'pic.avif', 'pic.jpg') }
        assert_includes error.message, source.inspect
        assert_includes error.message, 'block'
      end
    end

    it 'should take a last source without a known image type' do
      expected = '<picture><source srcset="/images/pic.webp" type="image/webp" />' \
                 '<img src="https://cdn.example.com/pic" alt="Pic" /></picture>'
      assert_equal expected, picture_tag('pic.webp', 'https://cdn.example.com/pic')
      assert_equal '<picture><img src="/images/pic.jxl" alt="Pic" /></picture>', picture_tag('pic.jxl')
    end

    it 'should write only an img for one source' do
      assert_equal '<picture><img src="/images/pic.jpg" alt="Pic" /></picture>', picture_tag('pic.jpg')
      assert_equal '<picture><img src="/images/pic.jpg" alt="Pic" /></picture>', picture_tag(['pic.jpg'])
    end

    it 'should pass options to the picture and the image option to the img' do
      options = { 'class' => 'hero', image: { alt: 'A hill', class: 'photo', srcset: { 'pic@2x.jpg' => '2x' } } }
      actual_html = picture_tag('pic.webp', 'pic.jpg', options)
      expected = '<picture class="hero"><source srcset="/images/pic.webp" type="image/webp" />' \
                 '<img src="/images/pic.jpg" alt="A hill" class="photo" srcset="/images/pic@2x.jpg 2x" /></picture>'
      assert_equal expected, actual_html
      assert_equal %w[class image], options.keys.map(&:to_s)
    end

    it 'should take string keys in the image option' do
      symbol_keys = picture_tag('pic.webp', 'pic.jpg', image: { alt: 'A hill', srcset: { 'pic@2x.jpg' => '2x' } })
      string_keys = picture_tag('pic.webp', 'pic.jpg', 'image' => { 'alt' => 'A hill', 'srcset' => { 'pic@2x.jpg' => '2x' } })
      assert_equal symbol_keys, string_keys
    end

    it 'should escape attribute values' do
      actual_html = picture_tag('a"b.webp', 'pic&.jpg', title: '<x>', image: { alt: '"y"' })
      expected = '<picture title="&lt;x&gt;"><source srcset="/images/a&quot;b.webp" type="image/webp" />' \
                 '<img src="/images/pic&amp;.jpg" alt="&quot;y&quot;" /></picture>'
      assert_equal expected, actual_html
    end

    it 'should write the block as the content of the picture' do
      actual_html = picture_tag(class: 'hero') do
        tag(:source, srcset: image_path('wide.jpg'), media: '(min-width: 800px)') + image_tag('narrow.jpg')
      end
      expected = '<picture class="hero"><source srcset="/images/wide.jpg" media="(min-width: 800px)" />' \
                 '<img src="/images/narrow.jpg" alt="Narrow" /></picture>'
      assert_equal expected, actual_html
    end

    it 'should refuse both sources and a block, or neither' do
      assert_raises(ArgumentError) { picture_tag('pic.jpg') { image_tag('pic.jpg') } }
      assert_raises(ArgumentError) { picture_tag }
      assert_raises(ArgumentError) { picture_tag(class: 'hero') }
    end

    it 'should refuse the image option with a block' do
      assert_raises(ArgumentError) { picture_tag(image: { alt: 'A hill' }) { image_tag('pic.jpg') } }
    end
  end

  describe 'for #stylesheet_link_tag method' do
    it 'should display stylesheet link item' do
      time = stop_time_for_test
      actual_html = stylesheet_link_tag('style')
      expected_options = { rel: 'stylesheet' }
      assert_html_has_tag(actual_html, 'link', expected_options.merge(href: "/stylesheets/style.css?#{time.to_i}"))
      assert actual_html.html_safe?
    end

    it 'should display stylesheet link item for long relative path' do
      time = stop_time_for_test
      expected_options = { rel: 'stylesheet' }
      actual_html = stylesheet_link_tag('example/demo/style')
      assert_html_has_tag(actual_html, 'link', expected_options.merge(href: "/stylesheets/example/demo/style.css?#{time.to_i}"))
    end

    it 'should display stylesheet link item with absolute path' do
      stop_time_for_test
      expected_options = { rel: 'stylesheet' }
      actual_html = stylesheet_link_tag('/css/style')
      assert_html_has_tag(actual_html, 'link', expected_options.merge(href: '/css/style.css'))
    end

    it 'should display stylesheet link item with uri root' do
      self.class.stubs(:uri_root).returns('/blog')
      time = stop_time_for_test
      expected_options = { rel: 'stylesheet' }
      actual_html = stylesheet_link_tag('style')
      assert_html_has_tag(actual_html, 'link', expected_options.merge(href: "/blog/stylesheets/style.css?#{time.to_i}"))
    end

    it 'should display stylesheet link items' do
      time = stop_time_for_test
      actual_html = stylesheet_link_tag('style', 'layout.css', 'http://google.com/style.css')
      assert_html_has_tag(actual_html, 'link', rel: 'stylesheet', count: 3)
      assert_html_has_tag(actual_html, 'link', href: "/stylesheets/style.css?#{time.to_i}")
      assert_html_has_tag(actual_html, 'link', href: "/stylesheets/layout.css?#{time.to_i}")
      assert_html_has_tag(actual_html, 'link', href: 'http://google.com/style.css')
      assert_equal actual_html, stylesheet_link_tag(['style', 'layout.css', 'http://google.com/style.css'])
    end

    it 'should not use a timestamp if stamp setting is false' do
      self.class.expects(:asset_stamp).returns(false)
      expected_options = { rel: 'stylesheet' }
      assert_html_has_tag(stylesheet_link_tag('style'), 'link', expected_options.merge(href: '/stylesheets/style.css'))
    end

    it 'should display stylesheet link used custom options' do
      assert_html_has_tag(stylesheet_link_tag('style', media: 'screen'), 'link', rel: 'stylesheet', media: 'screen')
    end

    it 'should not write a type attribute by default' do
      actual_html = stylesheet_link_tag('style', 'layout')
      assert_html_has_tag(actual_html, 'link', rel: 'stylesheet', count: 2)
      assert_html_has_no_tag(actual_html, 'link[type]')
    end

    it 'should write a type attribute given as an option' do
      actual_html = stylesheet_link_tag('style', type: 'text/css')
      assert_html_has_tag(actual_html, 'link', rel: 'stylesheet', type: 'text/css')
    end
  end

  describe 'for #javascript_include_tag method' do
    it 'should display javascript item' do
      time = stop_time_for_test
      actual_html = javascript_include_tag('application')
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/application.js?#{time.to_i}")
      assert actual_html.html_safe?
    end

    it 'should respond to js_asset_folder setting' do
      time = stop_time_for_test
      self.class.stubs(:js_asset_folder).returns('js')
      assert_equal 'js', asset_folder_name(:js)
      actual_html = javascript_include_tag('application')
      assert_html_has_tag(actual_html, 'script', src: "/js/application.js?#{time.to_i}")
    end

    it 'should display javascript item for long relative path' do
      time = stop_time_for_test
      actual_html = javascript_include_tag('example/demo/application')
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/example/demo/application.js?#{time.to_i}")
    end

    it 'should display javascript item for path containing js' do
      time = stop_time_for_test
      actual_html = javascript_include_tag 'test/jquery.json'
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/test/jquery.json?#{time.to_i}")
    end

    it 'should display javascript item for path containing period' do
      time = stop_time_for_test
      actual_html = javascript_include_tag 'test/jquery.min'
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/test/jquery.min.js?#{time.to_i}")
    end

    it 'should display javascript item with absolute path' do
      actual_html = javascript_include_tag('/js/application')
      assert_html_has_tag(actual_html, 'script', src: '/js/application.js')
    end

    it 'should display javascript item with uri root' do
      self.class.stubs(:uri_root).returns('/blog')
      time = stop_time_for_test
      actual_html = javascript_include_tag('application')
      assert_html_has_tag(actual_html, 'script', src: "/blog/javascripts/application.js?#{time.to_i}")
    end

    it 'should not append extension to absolute paths' do
      actual_html = javascript_include_tag('https://maps.googleapis.com/maps/api/js?key=value&sensor=false')
      assert_html_has_tag(actual_html, 'script', src: 'https://maps.googleapis.com/maps/api/js?key=value&sensor=false')
    end

    it 'should display javascript items' do
      time = stop_time_for_test
      actual_html = javascript_include_tag('application', 'base.js', 'http://google.com/lib.js')
      assert_html_has_tag(actual_html, 'script', count: 3)
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/application.js?#{time.to_i}")
      assert_html_has_tag(actual_html, 'script', src: "/javascripts/base.js?#{time.to_i}")
      assert_html_has_tag(actual_html, 'script', src: 'http://google.com/lib.js')
      assert_equal actual_html, javascript_include_tag(['application', 'base.js', 'http://google.com/lib.js'])
    end

    it 'should not use a timestamp if stamp setting is false' do
      self.class.expects(:asset_stamp).returns(false)
      actual_html = javascript_include_tag('application')
      assert_html_has_tag(actual_html, 'script', src: '/javascripts/application.js')
    end

    it 'should not write a type attribute by default' do
      actual_html = javascript_include_tag('application', 'base')
      assert_html_has_tag(actual_html, 'script', count: 2)
      assert_html_has_no_tag(actual_html, 'script[type]')
    end

    it 'should write a type attribute given as an option' do
      actual_html = javascript_include_tag('application', 'base', type: 'module')
      assert_html_has_tag(actual_html, 'script', type: 'module', count: 2)
    end
  end

  describe 'for #favicon_tag method' do
    it 'should display favicon' do
      time = stop_time_for_test
      actual_html = favicon_tag('icons/favicon.png')
      assert_html_has_tag(actual_html, 'link', rel: 'icon', type: 'image/png', href: "/images/icons/favicon.png?#{time.to_i}")
    end

    it 'should match type with file ext' do
      time = stop_time_for_test
      actual_html = favicon_tag('favicon.ico')
      assert_html_has_tag(actual_html, 'link', rel: 'icon', type: 'image/ico', href: "/images/favicon.ico?#{time.to_i}")
    end

    it 'should allow option overrides' do
      time = stop_time_for_test
      actual_html = favicon_tag('favicon.png', type: 'image/ico')
      assert_html_has_tag(actual_html, 'link', rel: 'icon', type: 'image/ico', href: "/images/favicon.png?#{time.to_i}")
    end
  end

  describe 'for #feed_tag method' do
    it 'should generate correctly link tag for rss' do
      assert_html_has_tag(feed_tag(:rss, '/blog/post.rss'), 'link', type: 'application/rss+xml', rel: 'alternate', href: '/blog/post.rss', title: 'rss')
    end

    it 'should generate correctly link tag for atom' do
      assert_html_has_tag(feed_tag(:atom, '/blog/post.atom'), 'link', type: 'application/atom+xml', rel: 'alternate', href: '/blog/post.atom', title: 'atom')
    end

    it 'should override options' do
      assert_html_has_tag(feed_tag(:rss, '/blog/post.rss', type: 'my-type', rel: 'my-rel', title: 'my-title'), 'link', type: 'my-type', rel: 'my-rel', href: '/blog/post.rss', title: 'my-title')
    end
  end

  describe 'for #asset_path method' do
    it 'should generate proper paths for js and css' do
      assert_match(%r{/javascripts/app.js\?\d+}, asset_path(:js, 'app'))
      assert_match(%r{/stylesheets/app.css\?\d+}, asset_path(:css, 'app'))
    end

    it 'should generate proper paths for images and other files' do
      assert_match(%r{/images/app.png\?\d+}, asset_path(:images, 'app.png'))
      assert_match(%r{/documents/app.pdf\?\d+}, asset_path(:documents, 'app.pdf'))
    end

    it 'should generate proper paths for public folder' do
      assert_match(%r{/files/file.ext\?\d+}, asset_path('files/file.ext'))
    end

    it 'should keep colons in asset names' do
      assert_match(%r{/images/a:b\.png\?\d+}, asset_path(:images, 'a:b.png'))
      assert_match(%r{/images/photos/10:30\.png\?\d+}, asset_path(:images, 'photos/10:30.png'))
    end

    it 'should prefix sources whose later lines look absolute' do
      assert_match(%r{\A/javascripts/data:}, asset_path(:js, "data:text/javascript,alert(1)//\n/x"))
      assert_match(%r{\A/images/javascript:}, asset_path(:images, "javascript:alert(1)//\nhttp://x"))
    end
  end

  describe 'for #preload_link_tag method' do
    it 'should resolve scripts, stylesheets and images like their tags' do
      time = stop_time_for_test
      actual_html = preload_link_tag('app.css')
      assert_html_has_tag(actual_html, 'link', rel: 'preload', as: 'style', href: "/stylesheets/app.css?#{time.to_i}")
      assert_equal stylesheet_link_tag('app')[/href="[^"]*"/], actual_html[/href="[^"]*"/]
      assert_equal javascript_include_tag('app')[/src="([^"]*)"/, 1], preload_link_tag('app.js')[/href="([^"]*)"/, 1]
      assert_equal image_tag('logo.PNG')[/src="([^"]*)"/, 1], preload_link_tag('logo.PNG')[/href="([^"]*)"/, 1]
    end

    it 'should resolve other sources from the public folder without the asset stamp' do
      assert_equal '<link rel="preload" href="/captions/en.vtt" as="track" crossorigin="anonymous" />', preload_link_tag('captions/en.vtt')
      assert_equal '<link rel="preload" href="/fonts/a.woff2" as="font" crossorigin="anonymous" />', preload_link_tag('fonts/a.woff2')
      assert_equal '<link rel="preload" href="/api/items" as="fetch" crossorigin="anonymous" />', preload_link_tag('api/items', as: :fetch)
      assert_equal '<link rel="preload" href="/data/my%20file.json" />', preload_link_tag('data/my file.json')
    end

    it 'should resolve unstamped sources under the uri root and keep absolute ones' do
      self.class.stubs(:uri_root).returns('/blog')
      assert_equal '<link rel="preload" href="/blog/fonts/a.woff2" as="font" crossorigin="anonymous" />', preload_link_tag('fonts/a.woff2')
      assert_equal '<link rel="preload" href="/fonts/my%20a.woff2" as="font" crossorigin="anonymous" />', preload_link_tag('/fonts/my a.woff2')
      assert_equal '<link rel="preload" href="//cdn.example.com/a.vtt" as="track" crossorigin="anonymous" />',
                   preload_link_tag('//cdn.example.com/a.vtt')
    end

    it 'should keep absolute paths and urls' do
      self.class.stubs(:uri_root).returns('/blog')
      assert_equal '<link rel="preload" href="/fonts/a.woff2" as="font" crossorigin="anonymous" />', preload_link_tag('/fonts/a.woff2')
      assert_equal '<link rel="preload" href="https://cdn.example.com/a.png?v=1" as="image" />', preload_link_tag('https://cdn.example.com/a.png?v=1')
    end

    it 'should resolve under the uri root' do
      self.class.stubs(:uri_root).returns('/blog')
      self.class.stubs(:asset_stamp).returns(false)
      assert_equal '<link rel="preload" href="/blog/stylesheets/app.css" as="style" />', preload_link_tag('app.css')
    end

    it 'should infer the destination from the extension' do
      { 'a.js' => 'script', 'a.css' => 'style', 'a.vtt' => 'track', 'a.otf' => 'font', 'a.ttf' => 'font',
        'a.woff' => 'font', 'a.WOFF2' => 'font', 'a.avif' => 'image', 'a.gif' => 'image', 'a.ico' => 'image',
        'a.jpeg' => 'image', 'a.jpg' => 'image', 'a.png' => 'image', 'a.svg' => 'image', 'a.webp' => 'image',
        'a.css?v=1#x' => 'style' }.each do |source, as|
        assert_equal %(rel="preload" href="/#{source}" as="#{as}"), preload_link_tag("/#{source}")[/rel=.*as="[^"]*"/]
      end
    end

    it 'should write no destination it cannot infer' do
      assert_equal '<link rel="preload" href="/data.json" />', preload_link_tag('/data.json')
    end

    it 'should infer the destination for a false or blank one' do
      assert_equal '<link rel="preload" href="/a.css" as="style" />', preload_link_tag('/a.css', as: false)
      assert_equal '<link rel="preload" href="/a.woff2" as="font" crossorigin="anonymous" />', preload_link_tag('/a.woff2', as: '')
      assert_equal '<link rel="preload" href="/data.json" />', preload_link_tag('/data.json', as: ' ')
    end

    it 'should write crossorigin for fonts, tracks and fetches unless told otherwise' do
      assert_equal '<link rel="preload" href="/a.vtt" as="track" crossorigin="anonymous" />', preload_link_tag('/a.vtt')
      assert_equal '<link rel="preload" href="/a.vtt" as="track" />', preload_link_tag('/a.vtt', crossorigin: false)
      assert_equal 'crossorigin="use-credentials"', preload_link_tag('/a.woff2', crossorigin: 'use-credentials')[/crossorigin="[^"]*"/]
      assert_equal '<link rel="preload" href="/a.woff2" as="font" />', preload_link_tag('/a.woff2', crossorigin: false)
      assert_equal '<link rel="preload" href="/a.css" as="style" />', preload_link_tag('/a.css')
      assert_equal '<link rel="preload" href="/a.css" as="style" crossorigin="anonymous" />', preload_link_tag('/a.css', crossorigin: true)
    end

    it 'should take explicit options' do
      assert_equal '<link rel="preload" href="/data" as="fetch" type="application/json" crossorigin="anonymous" fetchpriority="high" />',
                   preload_link_tag('/data', as: :fetch, type: 'application/json', crossorigin: true, fetchpriority: :high)
      assert_equal '<link rel="preload" href="/a.js" as="fetch" crossorigin="anonymous" />', preload_link_tag('/a.js', 'as' => 'fetch')
      assert_equal '<link rel="preload" href="/data" as="fetch" />', preload_link_tag('/data', as: :fetch, crossorigin: false)
      assert_equal '<link rel="preload" href="/a.woff2" as="font" type="font/woff2" crossorigin="anonymous" />',
                   preload_link_tag('/a.woff2', type: 'font/woff2')
    end

    it 'should match the destination case-insensitively' do
      self.class.stubs(:asset_stamp).returns(false)
      assert_equal '<link rel="preload" href="/a" as="font" crossorigin="anonymous" />', preload_link_tag('/a', as: 'Font')
      assert_equal '<link rel="preload" href="/stylesheets/a.css" as="style" />', preload_link_tag('a', as: 'Style')
      assert_equal '<link rel="modulepreload" href="/javascripts/a.js" />', preload_link_tag('a', as: :Module)
    end

    it 'should write a modulepreload link for modules' do
      self.class.stubs(:asset_stamp).returns(false)
      assert_equal '<link rel="modulepreload" href="/javascripts/app.js" />', preload_link_tag('app', as: :module)
      assert_equal '<link rel="modulepreload" href="https://cdn.example.com/app.mjs" />', preload_link_tag('https://cdn.example.com/app.mjs')
      assert_equal '<link rel="preload" href="https://cdn.example.com/app.mjs" as="script" />',
                   preload_link_tag('https://cdn.example.com/app.mjs', as: :script)
    end

    it 'should escape attribute values' do
      actual_html = preload_link_tag('https://example.com/a.css?a=1&b="2"', title: '<b>"x"</b>')
      assert_equal '<link rel="preload" href="https://example.com/a.css?a=1&amp;b=&quot;2&quot;" as="style" ' \
                   'title="&lt;b&gt;&quot;x&quot;&lt;/b&gt;" />', actual_html
      assert actual_html.html_safe?
    end
  end

  describe 'for #javascript_importmap_tag method' do
    def importmap_of(html)
      JSON.parse(html[%r{<script type="importmap"[^>]*>(.*?)</script>}m, 1])
    end

    it 'should map module names to javascript sources without the asset stamp' do
      actual_html = javascript_importmap_tag(imports: { 'app' => 'app', lib: 'vendor/lib.js', 'spaced' => 'my lib' })
      assert_equal({ 'imports' => { 'app' => '/javascripts/app.js', 'lib' => '/javascripts/vendor/lib.js',
                                    'spaced' => '/javascripts/my%20lib.js' } }, importmap_of(actual_html))
      assert_html_has_tag(actual_html, 'script', type: 'importmap', count: 1)
      assert_html_has_no_tag(actual_html, 'script[type=module]')
      assert_html_has_no_tag(actual_html, 'link')
    end

    it 'should keep sources with a scheme or a leading slash as given' do
      self.class.stubs(:uri_root).returns('/blog')
      sources = { 'cdn' => 'https://cdn.example.com/x', 'rel' => '//cdn.example.com/p', 'root' => '/js/y',
                  'lodash/' => '/vendor/lodash/', 'data' => 'data:text/javascript,export%20default%201', 'blob' => 'BLOB:x' }
      assert_equal({ 'imports' => sources }, importmap_of(javascript_importmap_tag(imports: sources)))
      assert_equal({ 'imports' => { 'a' => '/my%20a.js' } }, importmap_of(javascript_importmap_tag(imports: { 'a' => '/my a.js' })))
    end

    it 'should map a name ending in a slash as a prefix' do
      assert_equal({ 'imports' => { 'lib/' => '/javascripts/lib/', 'vendor/' => '/vendor/', 'cdn/' => 'https://cdn.example.com/x/' } },
                   importmap_of(javascript_importmap_tag(imports: { 'lib/' => 'lib', 'vendor/' => '/vendor', 'cdn/' => 'https://cdn.example.com/x' })))
    end

    it 'should raise for an import without a source' do
      [nil, '', '  '].each do |source|
        error = assert_raises(ArgumentError) { javascript_importmap_tag(imports: { 'app' => '/app.js', 'chart' => source }) }
        assert_includes error.message, '"chart"'
      end
    end

    it 'should take the options as a second hash' do
      assert_equal '<script type="importmap" nonce="n">{"imports":{"app":"/app.js"}}</script>',
                   javascript_importmap_tag({ imports: { 'app' => '/app.js' } }, { nonce: 'n' })
    end

    it 'should leave nil scopes and integrity out of the import map' do
      actual_html = javascript_importmap_tag(imports: { 'a' => '/a.js' }, scopes: nil, integrity: nil)
      assert_equal({ 'imports' => { 'a' => '/a.js' } }, importmap_of(actual_html))
      assert_html_has_no_tag(actual_html, 'script[scopes]')
    end

    it 'should write scopes and integrity into the import map' do
      scopes = { '/admin/' => { 'chart' => '/javascripts/chart-2.js' } }
      integrity = { '/javascripts/app.js' => 'sha384-</script>' }
      actual_html = javascript_importmap_tag(imports: { 'app' => 'app' }, scopes: scopes, integrity: integrity)
      assert_equal({ 'imports' => { 'app' => '/javascripts/app.js' }, 'scopes' => scopes, 'integrity' => integrity }, importmap_of(actual_html))
      assert_equal 1, actual_html.scan('</script').size
      assert_html_has_no_tag(actual_html, 'script[scopes]')
      assert_html_has_no_tag(actual_html, 'script[integrity]')
    end

    it 'should resolve a relative prefix to the javascripts folder' do
      self.class.stubs(:uri_root).returns('/blog')
      assert_equal({ 'imports' => { 'lib/' => '/blog/javascripts/lib/', 'app' => '/blog/javascripts/app.js' } },
                   importmap_of(javascript_importmap_tag(imports: { 'lib/' => 'lib/', 'app' => 'app' })))
    end

    it 'should write an empty import map without imports' do
      assert_equal '<script type="importmap">{"imports":{}}</script>', javascript_importmap_tag
    end

    it 'should import the entry from a module script' do
      actual_html = javascript_importmap_tag('application', 'imports' => { 'application' => '/application.js' })
      assert_equal '<script type="importmap">{"imports":{"application":"/application.js"}}</script>' \
                   '<script type="module">import "application"</script>', actual_html
      assert actual_html.html_safe?
    end

    it 'should write no module script for a blank entry' do
      assert_equal '<script type="importmap">{"imports":{}}</script>', javascript_importmap_tag('')
      assert_equal '<script type="importmap">{"imports":{}}</script>', javascript_importmap_tag(" \n", imports: {})
    end

    it 'should write a modulepreload link for each import when asked' do
      actual_html = javascript_importmap_tag('app', imports: { 'app' => '/app.js', 'cdn' => 'https://cdn.example.com/x.js' }, preload: true)
      assert_equal '<script type="importmap">{"imports":{"app":"/app.js","cdn":"https://cdn.example.com/x.js"}}</script>' \
                   '<link rel="modulepreload" href="/app.js" />' \
                   '<link rel="modulepreload" href="https://cdn.example.com/x.js" />' \
                   '<script type="module">import "app"</script>', actual_html
    end

    it 'should preload each address once' do
      actual_html = javascript_importmap_tag(imports: { 'app' => 'app', 'main' => 'app', 'x' => '/javascripts/app.js' }, preload: true)
      assert_equal 1, actual_html.scan('<link rel="modulepreload" href="/javascripts/app.js" />').size
    end

    it 'should not preload prefixes' do
      actual_html = javascript_importmap_tag(imports: { 'lib/' => 'lib/', 'app' => '/app.js' }, preload: true)
      assert_equal '<script type="importmap">{"imports":{"lib/":"/javascripts/lib/","app":"/app.js"}}</script>' \
                   '<link rel="modulepreload" href="/app.js" />', actual_html
    end

    it 'should write the nonce on each tag and other html options on the import map only' do
      actual_html = javascript_importmap_tag('app', imports: { 'app' => '/app.js' }, preload: true, nonce: 'r4nd"om',
                                                    id: 'map', 'data-turbo-track' => 'reload', type: 'text/plain')
      assert_equal '<script type="importmap" nonce="r4nd&quot;om" id="map" data-turbo-track="reload">{"imports":{"app":"/app.js"}}</script>' \
                   '<link rel="modulepreload" href="/app.js" nonce="r4nd&quot;om" />' \
                   '<script type="module" nonce="r4nd&quot;om">import "app"</script>', actual_html
    end

    it 'should escape import names and sources so they cannot end the script' do
      name = '</script><script>alert(1)</script><!--'
      source = 'https://cdn.example.com/x.js?a=1&b=</script>'
      actual_html = javascript_importmap_tag(name, imports: { name => source, "\u2028" => "/\u2029.js" })
      assert_equal 2, actual_html.scan(%r{</script}i).size
      refute_includes actual_html, '<!--'
      refute_match(/[\u2028\u2029]/, actual_html)
      assert_equal({ 'imports' => { name => source, "\u2028" => "/\u2029.js" } }, importmap_of(actual_html))
      entry = actual_html[%r{<script type="module">import (.*)</script>}m, 1]
      assert_equal name, JSON.parse("[#{entry}]").first
    end
  end
end
