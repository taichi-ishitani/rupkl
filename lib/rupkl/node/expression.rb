# frozen_string_literal: true

module RuPkl
  module Node
    class UnaryOperation
      def initialize(operator, operand, position)
        @operator = operator
        @operand = operand
        @position = position
      end

      attr_reader :operator
      attr_reader :operand
      attr_reader :position
    end
  end
end
