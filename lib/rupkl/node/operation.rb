# frozen_string_literal: true

module RuPkl
  module Node
    module OperationCommon
      include NodeCommon

      def initialize(parent, operator, *operands, position)
        super(parent, *operands, position)
        @operator = operator
        @operands = operands
      end

      attr_reader :operator
      attr_reader :operands

      def evaluate_lazily(_context = nil)
        self
      end

      def copy(parent = nil)
        copied_operands = operands.map(&:copy)
        self.class.new(parent, operator, *copied_operands, position)
      end

      private

      def s_op(context)
        r = receiver.evaluate(context)
        check_operator(r)

        k = key.evaluate(context)
        check_key_operand(r, k)

        (v = r.find_by_key(k)) ||
          begin
            message = "cannot find key '#{k.to_pkl_string(context)}'"
            raise EvaluationError.new(message, position)
          end

        v.evaluate
      end

      def u_op(context)
        o = operand.evaluate(context)
        check_operator(o)

        result =
          if operator == :-
            -o.value
          else
            !o.value
          end
        create_op_result(result)
      end

      def b_op(context)
        l = l_operand.evaluate(context)
        check_operator(l)
        return l if short_circuit?(l)

        r = r_operand.evaluate(context)
        check_r_operand(l, r)
          .then { return _1 if _1 }

        l, r = l.coerce(operator, r)
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

      def check_key_operand(receiver, key)
        invalid_key_operand?(receiver, key) &&
          begin
            message =
              "invalid key operand type #{key.class.basename} is given " \
              "for operator '#{operator}'"
            raise EvaluationError.new(message, position)
          end
      end

      def invalid_key_operand?(receiver, key)
        receiver.respond_to?(:invalid_key_operand?) &&
          receiver.invalid_key_operand?(key)
      end

      def check_r_operand(l_operand, r_operand)
        return unless invalid_r_operand?(l_operand, r_operand)

        if [:==, :'!='].include?(operator)
          create_op_result(operator != :==)
        else
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

      def ruby_op
        { '&&': :&, '||': :|, '~/': :/ }.fetch(operator, operator)
      end

      def create_op_result(result)
        case result
        when ::Integer then Int.new(parent, result, position)
        when ::Float then Float.new(parent, result, position)
        when ::String then String.new(parent, result, nil, position)
        when true, false then Boolean.new(parent, result, position)
        end
      end
    end

    class SubscriptOperation
      include OperationCommon

      def initialize(parent, operator, receiver, key, position)
        super
        @receiver = receiver
        @key = key
      end

      attr_reader :receiver
      attr_reader :key

      def evaluate(context = nil)
        s_op(context)
      end
    end

    class UnaryOperation
      include OperationCommon

      def initialize(parent, operator, operand, position)
        super
        @operand = operand
      end

      attr_reader :operand

      def evaluate(context = nil)
        u_op(context)
      end
    end

    class BinaryOperation
      include OperationCommon

      def initialize(parent, operator, l_operand, r_operand, position)
        super
        @l_operand = l_operand
        @r_operand = r_operand
      end

      attr_reader :l_operand
      attr_reader :r_operand
      attr_reader :position

      def evaluate(context = nil)
        b_op(context)
      end
    end
  end
end
