module Padrino
  module Routing
    module Helpers
      # Used to retrieve the full url for a given named route alias from the named_paths data
      # Accepts parameters which will be substituted into the url if necessary
      # url_for(:accounts) => '/accounts'
      # url_for(:account, :id => 5) => '/account/5'
      # url_for(:admin, show, :id => 5, :name => "demo") => '/admin/path/5/demo'
      def url_for(*route_name)
        params = route_name.extract_options!.reject { |name, val| val.blank? }
        route_name.unshift(self.class.app_name.to_sym) unless route_name.first == self.class.app_name.to_sym
        mapped_url = self.class.named_paths[route_name]
        raise Padrino::RouteNotFound.new("Route alias #{route_name.inspect} is not mapped to a url") unless mapped_url
        result_url = String.new(File.join(self.class.uri_root, mapped_url))
        result_url.scan(%r{/?(:\S+?)(?:/|$)}).each do |placeholder|
          param_key = placeholder[0][1..-1].to_sym
          param_obj = params.delete(param_key)
          param_value = param_obj.respond_to?(:to_param) ? param_obj.to_param : param_obj
          result_url.gsub!(Regexp.new(placeholder[0]), param_value.to_s)
        end
        result_url << "?" + params.to_params if params.any?
        result_url
      end
    end
  end
end