# frozen_string_literal: true

module Kkhay
  class Error < StandardError; end

  class ApiError < Error
    attr_reader :status, :code, :details

    def __initialize__(status, message, code = nil, details = nil)
      @status = status
      @code = code
      @details = details
      super("Kkhay::ApiError [HTTP #{status}]: #{message}")
    end

    def initialize(status, message, code = nil, details = nil)
      @status = status
      @code = code
      @details = details
      super("Kkhay::ApiError [HTTP #{status}]: #{message}")
    end
  end

  class SignatureVerificationError < Error; end
end

