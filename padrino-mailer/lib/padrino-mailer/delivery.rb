require 'rubygems'
require 'net/smtp'
begin
  require 'smtp_tls'
rescue LoadError
end
require 'base64'
require 'tmail'

module Padrino
  module Mailer
    module Delivery

      class << self

        def mail(options)
          raise(ArgumentError, ":to is required") unless options[:to]
          via = options.delete(:via)
          if via.nil?
            transport build_tmail(options)
          else
            if via_options.include?(via.to_s)
              send("transport_via_#{via}", build_tmail(options), options)
            else
              raise(ArgumentError, ":via must be either smtp or sendmail")
            end
          end
        end

        def build_tmail(options)
          mail          = TMail::Mail.new
          mail.to       = options[:to]
          mail.cc       = options[:cc]   || ''
          mail.bcc      = options[:bcc]  || ''
          mail.from     = options[:from] || 'padrino@unknown'
          mail.reply_to = options[:reply_to]
          mail.subject  = options[:subject]

          if options[:attachments]
            # If message has attachment, then body must be sent as a message part
            # or it will not be interpreted correctly by client.
            body = TMail::Mail.new
            body.body = options[:body] || ""
            body.content_type = options[:content_type] || "text/plain"
            mail.parts.push body
            (options[:attachments] || []).each do |name, body|
              attachment = TMail::Mail.new
              attachment.transfer_encoding = "base64"
              attachment.body = Base64.encode64(body)
              content_type = MIME::Types.type_for(name).to_s
              attachment.content_type = content_type unless content_type == ""
              attachment.set_content_disposition "attachment", "filename" => name
              mail.parts.push attachment
            end
          else
            mail.content_type = options[:content_type] || "text/plain"
            mail.body = options[:body] || ""
          end
          mail.charset = options[:charset] || "UTF-8" # charset must be set after setting content_type
          mail
        end

        def sendmail_binary
          @sendmail_binary ||= `which sendmail`.chomp
        end

        def transport(tmail)
          if File.executable? sendmail_binary
            transport_via_sendmail(tmail)
          else
            transport_via_smtp(tmail)
          end
        end

        def via_options
          %w(sendmail smtp)
        end

        def transport_via_sendmail(tmail, options={})
          logger.debug "Sending email via sendmail:\n#{tmail}" if Kernel.respond_to?(:logger)
          IO.popen('-', 'w+') do |pipe|
            if pipe
              pipe.write(tmail.to_s)
            else
              exec(sendmail_binary, *tmail.to)
            end
          end
        end

        def transport_via_smtp(tmail, options={:smtp => {}})
          logger.debug "Sending email via smtp:\n#{tmail}" if Kernel.respond_to?(:logger)
          o = { :host => 'localhost', :port => '25', :domain => 'localhost.localdomain' }
          o.merge!(options[:smtp]) if options[:smtp].is_a?(Hash)
          smtp = Net::SMTP.new(o[:host], o[:port])
          if o[:tls]
            raise "You may need: gem install smtp_tls" unless smtp.respond_to?(:enable_starttls)
            smtp.enable_starttls
          end
          if o.include?(:auth)
            smtp.start(o[:domain], o[:user], o[:pass] || o[:password], o[:auth])
          else
            smtp.start(o[:domain])
          end
          smtp.send_message tmail.to_s, tmail.from, tmail.to
          smtp.finish
        end
      end
    end # Delivery
  end # Mailer
end # Padrino