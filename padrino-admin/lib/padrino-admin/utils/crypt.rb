require 'openssl'

module Padrino
  module Admin
    ##
    # Common utility methods used within the admin application.
    #
    module Utils
      ##
      # This util it's used for encrypt/decrypt password.
      # We want password decryptable because generally for our sites we have: password_lost.
      # We prefer send original password instead reset them.
      #
      module Crypt
        ##
        # Decrypts the current string using the current key specified
        #
        def decrypt(password)
          cipher = build_cipher(:decrypt, password)
          cipher.update(self.unpack('m')[0]) + cipher.final
        end

        ##
        # Encrypts the current string using the current key and algorithm specified
        #
        def encrypt(password)
          cipher = build_cipher(:encrypt, password)
          [cipher.update(self) + cipher.final].pack('m').chomp
        end

      private
        def build_cipher(type, password) # @private
          cipher = OpenSSL::Cipher::Cipher.new("DES-EDE3-CBC").send(type)
          cipher.pkcs5_keyivgen(password)
          cipher
        end
      end # Crypt
    end # Utils
  end # Admin
end # Padrino
