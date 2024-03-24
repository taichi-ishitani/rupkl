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
