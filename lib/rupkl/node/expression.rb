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

      def evaluate(scopes)
        o = operand.evaluate(scopes)
        o.u_op(operator)
      end

      def to_ruby(scopes)
        evaluate(scopes).to_ruby(scopes)
      end
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

      def evaluate(scopes)
        l = l_operand.evaluate(scopes)
        l.b_op(operator, r_operand, scopes)
      end

      def to_ruby(scopes)
        evaluate(scopes).to_ruby(scopes)
      end
    end
  end
end
