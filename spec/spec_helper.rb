# frozen_string_literal: true

require 'bundler/setup'
require_relative 'support/matchers'
require_relative 'support/helpers'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RuPkl::ParserHelpers, :parser

  if ENV.key?('COVERAGE')
    require 'simplecov'
    SimpleCov.start

    if ENV.key?('CI')
      require 'simplecov-cobertura'
      SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
    end
  end
end

require 'rupkl'
