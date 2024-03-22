# frozen_string_literal: true

module RuPkl
  module Node
    module Operatable
      def u_op(operator)
        check_operator(operator)
        create_result(value.__send__(:"#{operator}@"))
      end

      def b_op(operator, r_operand)
        check_operator(operator)
        check_operand(operator, r_operand)

        o, l, r = coerce(operator, self, r_operand)
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

      def check_operand(operator, r_operand)
        invalid_operand?(r_operand) &&
          begin
            message =
              "invalid operand type #{r_operand.class.basename} is given " \
              "for operator '#{operator}'"
            raise EvaluationError.new(message, position)
          end
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
