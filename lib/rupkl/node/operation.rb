# frozen_string_literal: true

module RuPkl
  module Node
    module OperationCommon
      include NodeCommon

      def evaluate_lazily(_scopes)
        self
      end

      private

      def s_op(scopes)
        r = receiver.evaluate(scopes)
        check_operator(r)

        k = key.evaluate(scopes)
        check_key_operand(r, k)

        r.find_by_key(k) ||
          begin
            message = "cannot find key '#{k.to_pkl_string(scopes)}'"
            raise EvaluationError.new(message, position)
          end
      end

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

      def ruby_op
        { '&&': :&, '||': :|, '~/': :/ }.fetch(operator, operator)
      end

      def create_op_result(result)
        case result
        when ::Integer then Integer.new(result, position)
        when ::Float then Float.new(result, position)
        when ::String then String.new(result, nil, position)
        when ::TrueClass, ::FalseClass then Boolean.new(result, position)
        end
      end
    end

    class SubscriptOperation
      include OperationCommon

      def initialize(receiver, key, position)
        super
        @receiver = receiver
        @key = key
      end

      attr_reader :receiver
      attr_reader :key

      def operator
        :[]
      end

      def evaluate(scopes)
        s_op(scopes)
      end
    end

    class UnaryOperation
      include OperationCommon

      def initialize(operator, operand, position)
        super(operand, position)
        @operator = operator
        @operand = operand
      end

      attr_reader :operator
      attr_reader :operand

      def evaluate(scopes)
        u_op(scopes)
      end
    end

    class BinaryOperation
      include OperationCommon

      def initialize(operator, l_operand, r_operand, position)
        super(l_operand, r_operand, position)
        @operator = operator
        @l_operand = l_operand
        @r_operand = r_operand
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
