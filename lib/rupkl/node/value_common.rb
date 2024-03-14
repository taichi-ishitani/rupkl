# frozen_string_literal: true

module RuPkl
  module Node
    module ValueCommon
      def initialize(value, position)
        @value = value
        @position = position
      end

      attr_reader :value
      attr_reader :position
    end
  end
end