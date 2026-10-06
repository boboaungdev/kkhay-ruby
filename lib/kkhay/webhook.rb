# frozen_string_literal: true

require "openssl"
require "json"

module Kkhay
  module Webhook
    class << self
      # Verifies the cryptographic HMAC-SHA256 signature sent with incoming K Khay IPN webhooks.
      #
      # @param payload [String, Hash] The raw request body or hash
      # @param signature [String] The x-kkhay-signature header value
      # @param ipn_secret [String] Your merchant IPN Secret Key
      # @return [Boolean] true if signature matches
      def verify_signature(payload, signature, ipn_secret)
        return false if signature.nil? || signature.to_s.strip.empty? || ipn_secret.nil? || ipn_secret.to_s.strip.empty?

        raw_body = payload.is_a?(String) ? payload : JSON.generate(payload)
        expected = OpenSSL::HMAC.hexdigest("SHA256", ipn_secret.to_s, raw_body)

        secure_compare(expected, signature.to_s.strip)
      rescue StandardError
        false
      end

      # Validates and parses incoming webhook payload into a Ruby Hash with symbolize_names.
      #
      # @raise [SignatureVerificationError] if signature is invalid
      def parse_event(raw_body, signature, ipn_secret)
        unless verify_signature(raw_body, signature, ipn_secret)
          raise SignatureVerificationError, "Invalid K Khay webhook signature: Request rejected."
        end

        JSON.parse(raw_body, symbolize_names: true)
      rescue JSON::ParserError => e
        raise ArgumentError, "Failed to parse webhook JSON payload: #{e.message}"
      end

      private

      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C*")
        r = b.unpack("C*")
        res = 0
        l.each_with_index do |byte, i|
          res |= byte ^ r[i]
        end
        res.zero?
      end
    end
  end
end

