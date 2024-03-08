# frozen_string_literal: true

module RuPkl
  class RuPklError < StandardError
  end

  class ParseError < RuPklError
    def initialize(message, filename, line, column, cause)
      super(message)
      @filename = filename
      @line = line
      @column = column
      @cause = cause
    end

    attr_reader :filename
    attr_reader :line
    attr_reader :column
    attr_reader :cause
  end
end
