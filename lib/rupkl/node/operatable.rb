# frozen_string_literal: true

module RuPkl
  module Node
    module Operatable
      def u_op(operator)
        check_operator(operator)

        result =
          operator == :- && -value || !value
        create_result(result)
      end

      def b_op(operator, r_operand, scopes)
        check_operator(operator)
        return self if short_circuit?(operator)

        operand = r_operand.evaluate(scopes)
        check_operand(operator, operand)

        o, l, r = coerce(operator, self, operand)
        create_result(l.__send__(o, r))
      end

      private

      def check_operator(operator)
        undefined_operator?(operator) &&
          begin
            message =
              "operator '#{operator}' is not defined for " \
              "#{self.class.basename} type"
            raise EvaluationError.new(message, position)
          end
      end

      def short_circuit?(_operator)
        false
      end

      def check_operand(operator, r_operand)
        invalid_operand?(r_operand) &&
          begin
            message =
              "invalid operand type #{r_operand.class.basename} is given " \
              "for operator '#{operator}'"
            raise EvaluationError.new(message, position)
          end
      end

      def invalid_operand?(operand)
        !operand.is_a?(self.class)
      end

      def create_result(value)
        klass =
          case value
          when ::Integer then Integer
          when ::Float then Float
          when ::TrueClass, ::FalseClass then Boolean
          end
        klass.new(value, position)
      end
    end
  end
end
