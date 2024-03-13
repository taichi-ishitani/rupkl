# frozen_string_literal: true

module RuPkl
  module Node
    class PklClassProperty
      def initialize(name, value, position)
        @name = name
        @value = value
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :position
    end
  end
end
