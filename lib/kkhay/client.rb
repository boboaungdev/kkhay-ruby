# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Kkhay
  class Client
    attr_reader :api_key, :base_url, :timeout

    # Initializes the K Khay Client
    #
    # @param api_key [String] Your merchant API key
    # @param base_url [String] Custom gateway URL (defaults to https://api.kkhay.com)
    # @param timeout [Integer] Timeout in seconds (defaults to 30)
    def initialize(api_key: nil, base_url: "https://api.kkhay.com", timeout: 30)
      @api_key = (api_key || Kkhay.configuration&.api_key).to_s.strip
      raise ArgumentError, "Kkhay::Client: A valid 'api_key' is required." if @api_key.empty?

      @base_url = (base_url || "https://api.kkhay.com").sub(%r{/+\z}, "")
      @timeout = timeout.to_i
    end

    # Creates a new crypto payment invoice
    #
    # @param params [Hash] Invoice parameters (:price_amount, :pay_network, :pay_token, etc.)
    # @return [Hash] Parsed response containing invoice details and hosted_url
    def create_invoice(params)
      price = params[:price_amount] || params["priceAmount"]
      network = params[:pay_network] || params["payNetwork"]
      token = params[:pay_token] || params["payToken"]

      raise ArgumentError, "create_invoice: :price_amount must be greater than 0" if price.to_f <= 0
      raise ArgumentError, "create_invoice: :pay_network is required (e.g. 'bsc', 'polygon')" if network.to_s.empty?
      raise ArgumentError, "create_invoice: :pay_token is required (e.g. 'USDT', 'USDC')" if token.to_s.empty?

      payload = {
        priceAmount: price.to_f,
        payNetwork: network.to_s,
        payToken: token.to_s,
        priceCurrency: (params[:price_currency] || params["priceCurrency"] || "USD").to_s,
      }

      payload[:orderId] = (params[:order_id] || params["orderId"]).to_s if params[:order_id] || params["orderId"]
      payload[:title] = (params[:title] || params["title"]).to_s if params[:title] || params["title"]
      payload[:customerName] = (params[:customer_name] || params["customerName"]).to_s if params[:customer_name] || params["customerName"]
      payload[:customerEmail] = (params[:customer_email] || params["customerEmail"]).to_s if params[:customer_email] || params["customerEmail"]
      payload[:redirectUrl] = (params[:redirect_url] || params["redirectUrl"]).to_s if params[:redirect_url] || params["redirectUrl"]
      payload[:cancelUrl] = (params[:cancel_url] || params["cancelUrl"]).to_s if params[:cancel_url] || params["cancelUrl"]
      payload[:ipnCallbackUrl] = (params[:ipn_callback_url] || params["ipnCallbackUrl"]).to_s if params[:ipn_callback_url] || params["ipnCallbackUrl"]
      payload[:metadata] = params[:metadata] if params[:metadata]

      request("/v1/merchant/invoices", method: :post, body: payload)
    end

    # Retrieves an invoice by UUID
    #
    # @param invoice_id [String] The unique invoice ID
    # @return [Hash] Invoice details and blockchain confirmations
    def get_invoice(invoice_id)
      raise ArgumentError, "get_invoice: invoice_id is required" if invoice_id.to_s.strip.empty?

      request("/v1/merchant/invoices/#{URI.encode_www_form_component(invoice_id.to_s.strip)}", method: :get)
    end

    # Lists and paginates merchant invoices
    #
    # @param query [Hash] Filtering and pagination options (:page, :limit, :status, :search)
    # @return [Hash] Paginated invoice records
    def list_invoices(query = {})
      query_params = {}
      query_params["page"] = query[:page] || query["page"] if query[:page] || query["page"]
      query_params["limit"] = query[:limit] || query["limit"] if query[:limit] || query["limit"]
      query_params["status"] = query[:status] || query["status"] if query[:status] || query["status"]
      query_params["search"] = query[:search] || query["search"] if query[:search] || query["search"]

      query_str = query_params.empty? ? "" : "?#{URI.encode_www_form(query_params)}"
      request("/v1/merchant/invoices#{query_str}", method: :get)
    end

    # Checks the health of the gateway
    def check_health
      request("/health", method: :get)
    end

    private

    def build_url(path)
      clean = path.start_with?("/") ? path : "/#{path}"
      if @base_url.end_with?("/api") || @base_url.include?("api.")
        "#{@base_url}#{clean}"
      else
        "#{@base_url}/api#{clean}"
      end
    end

    def request(path, method: :get, body: nil)
      uri = URI.parse(build_url(path))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = @timeout
      http.open_timeout = @timeout

      req = case method
            when :post then Net::HTTP::Post.new(uri.request_uri)
            else Net::HTTP::Get.new(uri.request_uri)
            end

      req["Accept"] = "application/json"
      req["x-api-key"] = @api_key
      req["User-Agent"] = "kkhay-ruby/#{Kkhay::VERSION}"

      if body
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end

      response = http.request(req)
      parsed = JSON.parse(response.body, symbolize_names: true) rescue {}

      status_code = response.code.to_i
      if status_code >= 400
        msg = parsed[:message] || parsed[:error] || "HTTP #{status_code} Error"
        raise ApiError.new(status_code, msg, parsed[:code], parsed[:details])
      end

      parsed
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ApiError.new(408, "Request timed out after #{@timeout}s")
    rescue ApiError
      raise
    rescue StandardError => e
      raise ApiError.new(500, "Network error: #{e.message}")
    end
  end
end

