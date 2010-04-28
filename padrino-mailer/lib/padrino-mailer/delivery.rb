require 'rubygems'
require 'net/smtp'
begin
  require 'smtp_tls'
rescue LoadError
end
require 'base64'
require 'mail'

module Padrino
  module Mailer
    module Delivery

      class << self
        def mail(options)
          raise(ArgumentError, ":to is required") unless options[:to]
          via = options.delete(:via)
          mail = build_mail(options)
          if via.nil?
            transport(mail)
          elsif via.present? && via_options.include?(via.to_s)
            method("transport_via_#{via}").call(mail, options)
          else # via option is incorrect
            raise(ArgumentError, ":via must be either smtp or sendmail")
          end
        end

        def build_mail(options)
          mail = Mail.new
          mail.to       = options[:to]
          mail.cc       = options[:cc]   || ''
          mail.bcc      = options[:bcc]  || ''
          mail.from     = options[:from] || 'padrino@unknown'
          mail.reply_to = options[:reply_to]
          mail.subject  = options[:subject]
          mail.body = options[:body] || ""
          mail.content_type = options[:content_type] || "text/plain"
          Array(options[:attachments]).each do |name, body|
            add_file(:filename => name, :content => body)
          end
          mail.charset = options[:charset] || "UTF-8" # charset must be set after setting content_type
          mail
        end

        def sendmail_binary
          @sendmail_binary ||= `which sendmail`.chomp
        end

        def via_options
          %w(sendmail smtp)
        end

        def transport(mail)
          if File.executable? sendmail_binary
            transport_via_sendmail(mail)
          else
            transport_via_smtp(mail)
          end
        end

        def transport_via_sendmail(mail, options={})
          mail.delivery_method :sendmail
          mail.deliver!
        end

        def transport_via_smtp(mail, options={:smtp => {}})
          logger.debug "Sending email via smtp:\n#{mail}" if Kernel.respond_to?(:logger)
          o = { :host => 'localhost', :port => '25', :domain => 'localhost.localdomain' }
          o.merge!(options[:smtp]) if options[:smtp].is_a?(Hash)
          o[:user_name] = o[:user] if o[:user].present?
          mail.delivery_method :smtp, o
          mail.deliver!
        end
      end
    end # Delivery
  end # Mailer
end # Padrino