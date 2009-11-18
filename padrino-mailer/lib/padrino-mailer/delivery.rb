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
          mail = TMail::Mail.new
          mail.to = options[:to]
          mail.from = options[:from] || 'pony@unknown'
          mail.subject = options[:subject]
          mail.body = options[:body] || ""
          mail.set_content_type 'text', options[:type] || 'plain', {'charset'=> options[:charset] || 'utf-8'}
          (options[:attachments] || []).each do |name, body|
            attachment = TMail::Mail.new
            attachment.transfer_encoding = "base64"
            attachment.body = Base64.encode64(body)
            # attachment.set_content_type # TODO: if necessary
            attachment.set_content_disposition "attachment", "filename" => name
            mail.parts.push attachment
          end
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
          IO.popen('-', 'w+') do |pipe|
            if pipe
              pipe.write(tmail.to_s)
            else
              exec(sendmail_binary, *tmail.to)
            end
          end
        end

        def transport_via_smtp(tmail, options={:smtp => {}})
          default_options = {:smtp => { :host => 'localhost', :port => '25', :domain => 'localhost.localdomain' }}
          o = default_options[:smtp].merge(options[:smtp])
          smtp = Net::SMTP.new(o[:host], o[:port])
          if o[:tls]
            raise "You may need: gem install smtp_tls" unless smtp.respond_to?(:enable_starttls)
            smtp.enable_starttls
          end
          if o.include?(:auth)
            smtp.start(o[:domain], o[:user], o[:password], o[:auth])
          else
            smtp.start(o[:domain])
          end
          smtp.send_message tmail.to_s, tmail.from, tmail.to
          smtp.finish
        end
      end
    end
  end
end
