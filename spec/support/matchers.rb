# frozen_string_literal: true

RSpec::Matchers.define(:parse_string) do |input, root = nil|
  result = nil
  expectation = nil
  trace = nil

  match do |parser|
    begin
      result = parser.parse(input.chomp, root: root)
      values_match?(expectation, result)
    rescue RuPkl::ParseError => e
      trace = e.cause&.ascii_tree
      false
    end
  end

  match_when_negated do |parser|
    begin
      parser.parse(input.chomp, root: root)
      false
    rescue RuPkl::ParseError => e
      trace = e.cause&.ascii_tree
      true
    end
  end

  failure_message do |parser|
    if expectation.nil?
      "expected result is not given."
    elsif result.nil?
      "expected #{root} parser to be able to parse #{input.inspect}, but it didn't.\n" \
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
    "expected #{root} parser not to parse #{input.inspect}, but it did."
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
