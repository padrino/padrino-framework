module Padrino
  module Routing
    module Helpers
      # Used to retrieve the full url for a given named route alias from the named_paths data
      # Accepts parameters which will be substituted into the url if necessary
      # url_for(:accounts) => '/accounts'
      # url_for(:account, :id => 5) => '/account/5'
      # url_for(:admin, show, :id => 5, :name => "demo") => '/admin/path/5/demo'
      def url_for(*route_name)
        values = route_name.extract_options!
        mapped_url = self.class.named_paths[route_name] || self.class.named_paths[route_name.dup.unshift(self.class.app_name.to_sym)]
        raise Padrino::RouteNotFound.new("Route alias #{route_name.inspect} is not mapped to a url") unless mapped_url
        result_url = String.new(File.join(self.class.uri_root, mapped_url))
        result_url.scan(%r{/?(:\S+?)(?:/|$)}).each do |placeholder|
          value_key = placeholder[0][1..-1].to_sym
          result_url.gsub!(Regexp.new(placeholder[0]), values.delete(value_key).to_s)
        end
        result_url << "?" + values.collect { |name, val| "#{name}=#{val}" }.join("&") if values.any?
        result_url
      end
    end
  end
end