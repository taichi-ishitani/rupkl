# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      def initialize(receiver, member, position)
        @receiver = receiver
        @member = member
        @position = position
      end

      attr_reader :receiver
      attr_reader :member
      attr_reader :position

      def evaluate(scopes)
        member_node =
          if receiver
            find_member([receiver.evaluate(scopes)])
          else
            find_member(scopes)
          end
        member_node.evaluate(scopes).value
      end

      private

      def find_member(scopes)
        scopes.reverse_each do |scope|
          node = scope&.properties&.find { _1.name.id == member.id }
          return node if node
        end

        raise EvaluationError.new("cannot find property '#{member.id}'", position)
      end
    end

    module OperationCommon
      def to_ruby(scopes)
        evaluate(scopes).to_ruby(scopes)
      end

      private

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

      def check_operand(l_operand, r_operand)
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
        o = operand.evaluate(scopes)
        u_op(o)
      end

      private

      def u_op(operand)
        check_operator(operand)

        result =
          operator == :- && -operand.value || !operand.value
        create_op_result(result)
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
        o = l_operand.evaluate(scopes)
        b_op(o, scopes)
      end

      private

      def b_op(l_operand, scopes)
        check_operator(l_operand)
        return l_operand if short_circuit?(l_operand)

        operand = r_operand.evaluate(scopes)
        check_operand(l_operand, operand)

        l, r = coerce(l_operand, operand)
        create_op_result(l.__send__(ruby_op, r))
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
    end
  end
end
