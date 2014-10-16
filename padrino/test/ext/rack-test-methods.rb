module Rack::Test::Methods
  # Delegate some methods to the last response
  alias_method :response, :last_response

  [:status, :headers, :body, :content_type, :ok?, :forbidden?].each do |method_name|
    define_method method_name do
      last_response.send(method_name)
    end
  end
end
