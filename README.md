# K Khay Ruby Gem 💎

Official Ruby gem for the **[K Khay Sovereign Crypto Payment Gateway](https://kkhay.com)**.

Accept non-custodial and custodial crypto payments (USDT, USDC, BNB, ETH across BSC, Polygon, Arbitrum, Base, and Ethereum) directly in **Ruby on Rails**, Sinatra, Hanami, or standalone Ruby backends with **zero external dependencies**.

---

## 📦 Installation

Add to your application's `Gemfile`:

```ruby
gem "kkhay"
```

And then execute:

```bash
bundle install
```

Or install it directly:

```bash
gem install kkhay
```

---

## ⚡ Quick Start

### 1. Global Rails Initializer (`config/initializers/kkhay.rb`)

```ruby
Kkhay.configure do |config|
  config.api_key = ENV["KKHAY_API_KEY"]
  # config.base_url = "https://api.kkhay.com" # default
  # config.timeout = 30 # default in seconds
end
```

### 2. Create an Invoice

```ruby
client = Kkhay.client

response = client.create_invoice(
  price_amount: 49.99,
  price_currency: "USD",
  pay_network: "bsc",
  pay_token: "USDT",
  order_id: "ORDER-7721",
  title: "Pro Membership",
  customer_email: "buyer@example.com",
  redirect_url: "https://myshop.com/orders/success",
  cancel_url: "https://myshop.com/cart"
)

invoice = response[:invoice]
puts "Invoice ID: #{invoice[:id]}"
puts "Hosted Checkout URL: #{invoice[:hostedUrl]}"
```

### 3. Check Invoice Status

```ruby
data = client.get_invoice("inv_9f81a7b2")
puts "Status: #{data[:invoice][:status]}"

data[:payments].each do |payment|
  puts "Tx: #{payment[:txHash]} (#{payment[:confirmations]} confirmations)"
end
```

---

## 🔐 Webhook / IPN Verification (Rails Controller)

```ruby
class KkhayWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.raw_post
    signature = request.headers["x-kkhay-signature"]
    secret = ENV["KKHAY_IPN_SECRET"]

    event = Kkhay::Webhook.parse_event(payload, signature, secret)

    if event[:event] == "payment.finished"
      order = Order.find_by(id: event[:order_id])
      order&.update!(status: "paid", tx_hash: event[:tx_hash])
    end

    head :ok
  rescue Kkhay::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end
end
```

---

## 📄 License

MIT © [K Khay](https://kkhay.com)

