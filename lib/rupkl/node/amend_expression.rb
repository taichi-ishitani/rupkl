# frozen_string_literal: true

module RuPkl
  module Node
    class AmendExpression
      def initialize(amending, bodies, position)
        @amending = amending
        @bodies = bodies
        @position = position
      end

      attr_reader :amending
      attr_reader :bodies
      attr_reader :position
    end
  end
end
