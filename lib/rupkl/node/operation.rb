# frozen_string_literal: true

module RuPkl
  module Node
    module Operatable
      def s_op(operator, key, context, position)
        check_s_op(operator, position)

        k = key.evaluate(context)
        valid_key_operand?(k) ||
          raise_invalid_key_error(operator, k, position)

        (v = find_by_key(k)) ||
          raise_no_key_found_error(k, context, position)

        v.evaluate
      end

      def u_op(operator, position)
        check_u_op(operator, position)
        __send__(u_op_method(operator), position)
      end

      def b_op(operator, operand, context, position)
        check_b_op(operator, position)
        return self if short_circuit?(operator)

        r_operand = operand.evaluate(context)
        if valid_r_operand?(operator, r_operand)
          __send__(b_op_method(operator), r_operand, position)
        elsif [:==, :'!='].any?(operator)
          Boolean.new(nil, operator != :==, position)
        else
          raise_invalid_r_operand_error(operator, r_operand, position)
        end
      end

      def b_op_eq(r_operand, position)
        result = self == r_operand
        Boolean.new(nil, result, position)
      end

      def b_op_ne(r_operand, position)
        result = self != r_operand
        Boolean.new(nil, result, position)
      end

      private

      def check_s_op(operator, position)
        check_operator(operator, position)
      end

      def valid_key_operand?(_key)
        true
      end

      def raise_invalid_key_error(operator, key, position)
        message =
          "invalid key operand type #{key.class.basename} is given " \
          "for operator '#{operator}'"
        raise EvaluationError.new(message, position)
      end

      def raise_no_key_found_error(key, context, position)
        message = "cannot find key '#{key.to_pkl_string(context)}'"
        raise EvaluationError.new(message, position)
      end

      def check_u_op(operator, position)
        op = :"#{operator}@"
        check_operator(op, position)
      end

      def u_op_method(operator)
        { '-': :u_op_minus, '!': :u_op_negate }[operator]
      end

      def check_b_op(operator, position)
        check_operator(operator, position)
      end

      def short_circuit?(_operator)
        false
      end

      def valid_r_operand?(_operator, operand)
        operand.is_a?(self.class)
      end

      def raise_invalid_r_operand_error(operator, r_operand, position)
        message =
          "invalid operand type #{r_operand.class.basename} is given " \
          "for operator '#{operator}'"
        raise EvaluationError.new(message, position)
      end

      def b_op_method(operator)
        {
          '**': :b_op_exp,
          '*': :b_op_mul, '/': :b_op_div,
          '~/': :b_op_truncating_div, '%': :b_op_rem,
          '+': :b_op_add, '-': :b_op_sub,
          '<': :b_op_lt, '>': :b_op_gt,
          '<=': :b_op_le, '>=': :b_op_ge,
          '==': :b_op_eq, '!=': :b_op_ne,
          '&&': :b_op_and, '||': :b_op_or
        }[operator]
      end

      def check_operator(operator, position)
        return if
          [:==, :'!='].any?(operator) || defined_operator?(operator)

        message =
          "operator '#{operator}' is not defined for " \
          "#{self.class.basename} type"
        raise EvaluationError.new(message, position)
      end

      def defined_operator?(_operator)
        false
      end
    end

    module OperationCommon
      include NodeCommon

      def initialize(parent, operator, *operands, position)
        super(parent, *operands, position)
        @operator = operator
        @operands = operands
      end

      attr_reader :operator
      attr_reader :operands

      def copy(parent = nil, position = @position)
        copied_operands = operands.map(&:copy)
        self.class.new(parent, operator, *copied_operands, position)
      end

      private

      def s_op(context)
        r = receiver.evaluate(context)
        r.s_op(operator, key, context, position)
      end

      def non_null_op(context)
        o = operand.evaluate(context)
        return o unless o.null?

        m = "expected a non-null value but got '#{o.to_pkl_string(context)}'"
        raise EvaluationError.new(m, position)
      end

      def u_op(context)
        o = operand.evaluate(context)
        o.u_op(operator, position)
      end

      def b_op(context)
        l = l_operand.evaluate(context)
        l.b_op(operator, r_operand, context, position)
      end

      def null_coalescing_op(context)
        l = l_operand.evaluate(context)
        return l unless l.null?

        r_operand.evaluate(context)
      end
    end

    class SubscriptOperation
      include OperationCommon

      def receiver
        operands.first
      end

      def key
        operands.last
      end

      def evaluate(context = nil)
        s_op(context)
      end
    end

    class NonNullOperation
      include OperationCommon

      def operand
        operands.first
      end

      def evaluate(context = nil)
        non_null_op(context)
      end
    end

    class UnaryOperation
      include OperationCommon

      def operand
        operands.first
      end

      def evaluate(context = nil)
        u_op(context)
      end
    end

    class BinaryOperation
      include OperationCommon

      def l_operand
        operands.first
      end

      def r_operand
        operands.last
      end

      def evaluate(context = nil)
        b_op(context)
      end
    end

    class NullCoalescingOperation
      include OperationCommon

      def l_operand
        operands.first
      end

      def r_operand
        operands.last
      end

      def evaluate(context = nil)
        null_coalescing_op(context)
      end
    end
  end
end
