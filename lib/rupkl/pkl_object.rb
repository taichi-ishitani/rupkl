# frozen_string_literal: true

module RuPkl
  class PklObject
    def initialize(properties, elements, entries)
      @properties = properties
      @elements = elements
      @entries = entries
    end

    attr_reader :properties
    attr_reader :elements
    attr_reader :entries
  end
end
