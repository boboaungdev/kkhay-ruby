# frozen_string_literal: true

require "minitest/autorun"
require "openssl"
require "json"
require_relative "../lib/kkhay"

class KkhayTest < Minitest::Test
  def test_configuration
    Kkhay.configure do |config|
      config.api_key = "kkhay_live_test_123"
    end

    assert_equal "kkhay_live_test_123", Kkhay.configuration.api_key
    assert_equal "https://api.kkhay.com", Kkhay.configuration.base_url

    client = Kkhay.client
    assert_equal "kkhay_live_test_123", client.api_key
  end

  def test_client_validation
    assert_raises(ArgumentError) do
      Kkhay::Client.new(api_key: "")
    end
  end

  def test_webhook_verification
    secret = "whsec_test_secret_123"
    payload = JSON.generate({
      event: "payment.finished",
      invoice_id: "inv_123",
      pay_amount: "50.00",
      pay_token: "USDT"
    })

    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    assert Kkhay::Webhook.verify_signature(payload, signature, secret)
    refute Kkhay::Webhook.verify_signature(payload + "tampered", signature, secret)
    refute Kkhay::Webhook.verify_signature(payload, signature, "wrong_secret")
    refute Kkhay::Webhook.verify_signature(payload, nil, secret)
  end

  def test_parse_event
    secret = "whsec_secret"
    payload = JSON.generate({
      event: "payment.finished",
      invoice_id: "inv_abc",
      status: "paid"
    })
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)

    event = Kkhay::Webhook.parse_event(payload, signature, secret)
    assert_equal "payment.finished", event[:event]
    assert_equal "inv_abc", event[:invoice_id]

    assert_raises(Kkhay::SignatureVerificationError) do
      Kkhay::Webhook.parse_event(payload, "invalid_sig", secret)
    end
  end
end

