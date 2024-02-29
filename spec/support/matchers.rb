# frozen_string_literal: true

RSpec::Matchers.define(:parse) do |input|
  result = nil
  expectation = nil
  trace = nil

  match do |parser|
    begin
      result = parser.parse(input)
      values_match?(expectation, result)
    rescue Parslet::ParseFailed => e
      trace = e.parse_failure_cause.ascii_tree
      false
    end
  end

  match_when_negated do |parser|
    begin
      parser.parse(input)
    rescue Parslet::ParseFailed => e
      trace = e.parse_failure_cause.ascii_tree
      true
    end
  end

  failure_message do |parser|
    if expectation.nil?
      "expected result is not given."
    elsif result.nil?
      "expected #{parser.inspect} to be able to parse #{input.inspect}, but it didn't.\n" \
      "trace:\n#{trace}" \
    elsif expectation.is_a?(RSpec::Matchers::BuiltIn::BaseMatcher)
      "output of parsing #{input.inspect} was mathced the expectation but it was #{result.inspect}\n" \
      "#{expectation.failure_message}"
    else
      "output of parsing #{input.inspect} was mathced the expectation.\n" \
      "expected: #{expectation.inspect}\n" \
      "  actual: #{result.inspect}"
    end
  end

  failure_message_when_negated do |parser|
    "expected #{parser.inspect} not to parse #{input.inspect}, but it did."
  end

  chain :as do |expected, &block|
    expectation =
      if block
        block.call
      else
        expected
      end
  end
end
