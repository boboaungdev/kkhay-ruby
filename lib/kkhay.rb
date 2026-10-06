# frozen_string_literal: true

require_relative "kkhay/version"
require_relative "kkhay/errors"
require_relative "kkhay/webhook"
require_relative "kkhay/client"

module Kkhay
  class Configuration
    attr_accessor :api_key, :base_url, :timeout

    def initialize
      @api_key = nil
      @base_url = "https://api.kkhay.com"
      @timeout = 30
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # Convenience method to instantiate a new client
    def client(api_key: nil, base_url: nil, timeout: nil)
      Client.new(
        api_key: api_key || configuration.api_key,
        base_url: base_url || configuration.base_url,
        timeout: timeout || configuration.timeout
      )
    end
  end
end

