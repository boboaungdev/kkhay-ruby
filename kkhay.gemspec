# frozen_string_literal: true

require_relative "lib/kkhay/version"

Gem::Specification.new do |spec|
  spec.name = "kkhay"
  spec.version = Kkhay::VERSION
  spec.authors = ["K Khay"]
  spec.email = ["dev@kkhay.com"]

  spec.summary = "Official Ruby Gem for K Khay Sovereign Crypto Payment Gateway"
  spec.description = "Accept non-custodial and custodial crypto payments (USDT, USDC, BNB, ETH on BSC, Polygon, Arbitrum, Base, Ethereum) in Ruby on Rails applications."
  spec.homepage = "https://kkhay.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/boboaungdev/kkhay-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/boboaungdev/kkhay-ruby/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/boboaungdev/kkhay-ruby/issues"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "README.md", "LICENSE"]
  end
  spec.require_paths = ["lib"]
end

