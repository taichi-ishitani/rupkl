# frozen_string_literal: true

module RuPkl
  class RuPklError < StandardError
  end

  class ParseError < RuPklError
    def initialize(message, position, cause)
      super(message)
      @position = position
      @cause = cause
    end

    attr_reader :position
    attr_reader :cause
  end

  class EvaluationError < RuPklError
    def initialize(message, position)
      super(message)
      @position = position
    end

    attr_reader :position
  end
end
