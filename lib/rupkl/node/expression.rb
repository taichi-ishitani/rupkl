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

    class BinaryOperation
      def initialize(operator, l_operand, r_operand, position)
        @operator = operator
        @l_operand = l_operand
        @r_operand = r_operand
        @position = position
      end

      attr_reader :operator
      attr_reader :l_operand
      attr_reader :r_operand
      attr_reader :position
    end
  end
end
