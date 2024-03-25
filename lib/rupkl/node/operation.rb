# frozen_string_literal: true

module RuPkl
  module Node
    module OperationCommon
      def to_ruby(scopes)
        evaluate(scopes).to_ruby(scopes)
      end

      private

      def u_op(scopes)
        o = operand.evaluate(scopes)
        check_operator(o)

        result =
          if operator == :-
            -o.value
          else
            !o.value
          end
        create_op_result(result)
      end

      def b_op(scopes)
        l = l_operand.evaluate(scopes)
        check_operator(l)
        return l if short_circuit?(l)

        r = r_operand.evaluate(scopes)
        check_r_operand(l, r)

        l, r = coerce(l, r)
        create_op_result(l.__send__(ruby_op, r))
      end

      def check_operator(operand)
        undefined_operator?(operand) &&
          begin
            message =
              "operator '#{operator}' is not defined for " \
              "#{operand.class.basename} type"
            raise EvaluationError.new(message, position)
          end
      end

      def undefined_operator?(operand)
        !operand.respond_to?(:undefined_operator?) ||
          operand.undefined_operator?(operator)
      end

      def check_r_operand(l_operand, r_operand)
        invalid_r_operand?(l_operand, r_operand) &&
          begin
            message =
              "invalid operand type #{r_operand.class.basename} is given " \
              "for operator '#{operator}'"
            raise EvaluationError.new(message, position)
          end
      end

      def invalid_r_operand?(l_operand, r_operand)
        if l_operand.respond_to?(:invalid_r_operand?)
          l_operand.invalid_r_operand?(r_operand)
        else
          !r_operand.is_a?(l_operand.class)
        end
      end

      def short_circuit?(l_operand)
        l_operand.respond_to?(:short_circuit?) &&
          l_operand.short_circuit?(operator)
      end

      def coerce(l_operand, r_operand)
        if l_operand.respond_to?(:coerce)
          l_operand.coerce(operator, r_operand)
        else
          [l_operand.value, r_operand.value]
        end
      end

      def ruby_op
        { '&&': :&, '||': :|, '~/': :/ }.fetch(operator, operator)
      end

      def create_op_result(result)
        klass =
          case result
          when ::Integer then Integer
          when ::Float then Float
          when ::TrueClass, ::FalseClass then Boolean
          end
        klass.new(result, position)
      end
    end

    class UnaryOperation
      include OperationCommon

      def initialize(operator, operand, position)
        @operator = operator
        @operand = operand
        @position = position
      end

      attr_reader :operator
      attr_reader :operand
      attr_reader :position

      def evaluate(scopes)
        u_op(scopes)
      end
    end

    class BinaryOperation
      include OperationCommon

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
        b_op(scopes)
      end
    end
  end
end
