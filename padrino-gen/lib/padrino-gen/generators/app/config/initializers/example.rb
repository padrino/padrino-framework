##
# Initializers can be used to configure information about your padrino app
# The following format is used because initializers are applied as plugins into the application
# 
module ExampleInitializer
  def self.registered(app)
    ##
    # Simple Redmine Issue
    # 
    #   app.error 500 do
    #     # Delivery error to our server
    #     boom = env['sinatra.error']
    #     body = ["#{boom.class} - #{boom.message}:", *boom.backtrace].join("\n  ")
    #     redmine = ["project: foo", "tracker: Bug", "priority: high"].join("\n")
    #     logger.error body
    #     Padrino::Mailer::MailObject.new(
    #       :subject => "[PROJECT] #{boom.class} - #{boom.message}",
    #       :to => "exceptions@foo.com", 
    #       :from => "help@foo.com", 
    #       :body => [body, redmine].join("\n\n")
    #     ).deliver
    #     response.status = 500
    #     content_type 'text/html', :charset => "utf-8"
    #     render "errors"
    #   end
  end
end