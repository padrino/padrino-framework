require 'oga'

module Padrino
  module TestMethods
    def assert_html_has_tag(html, tag, attributes={})
      assert html.html_safe?, 'output in not #html_safe?'
      assert_has_selector(html, tag, attributes)
    end

    def assert_html_has_no_tag(html, tag, attributes={})
      assert html.html_safe?, 'output in not #html_safe?'
      assert_has_no_selector(html, tag, attributes)
    end

    def assert_response_has_tag(tag, attributes={})
      assert_has_selector(last_response.body, tag, attributes)
    end

    def assert_response_has_no_tag(tag, attributes={})
      assert_has_no_selector(last_response.body, tag, attributes)
    end

    def assert_has_selector(html, selector, attributes)
      count_requirement = attributes.delete(:count)
      message = "'#{selector}' with attributes #{attributes} in html\n#{html}"
      matched_count = html_matched_tags(html, selector.to_s, attributes)
      if count_requirement
        assert_equal count_requirement, matched_count, "count of tags #{message}"
      else
        assert matched_count > 0, "expected a tag #{message}"
      end
    end

    def assert_has_no_selector(html, selector, attributes)
      message = "'#{selector}' with attributes #{attributes} in html\n#{html}"
      matched_count = html_matched_tags(html, selector.to_s, attributes)
      assert matched_count == 0, "expected no tags #{message}"
    end

    private

    def html_matched_tags(html, selector, attributes)
      @dom ||= Oga.parse_html(html)
      content_requirement = attributes.delete(:content)
      attributes.each do |name, value|
        selector += %{[#{name}="#{value}"]}
      end
      tags = @dom.css(selector.to_s.gsub(/\[([^"']*?)=([^'"]*?)\]/, '[\1="\2"]'))
      if content_requirement
        tags = tags.select{ |tag| (tag.get('content') || tag.text).index(content_requirement) }
      end
      tags.count
    end
  end
end
