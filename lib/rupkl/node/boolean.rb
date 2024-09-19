# frozen_string_literal: true

module RuPkl
  module Node
    class Boolean < Any
      include ValueCommon
      include Operatable

      uninstantiable_class

      def u_op_negate(position)
        Boolean.new(nil, !value, position)
      end

      def b_op_and(r_operand, position)
        result = value && r_operand.value
        Boolean.new(nil, result, position)
      end

      def b_op_or(r_operand, position)
        result = value || r_operand.value
        Boolean.new(nil, result, position)
      end

      define_builtin_method(:xor, other: Boolean) do |args, parent, position|
        result = value ^ args[:other].value
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:implies, other: Boolean) do |args, parent, position|
        result = !value || args[:other].value
        Boolean.new(parent, result, position)
      end

      private

      def defined_operator?(operator)
        [:'!@', :'&&', :'||'].any?(operator)
      end

      def short_circuit?(operator)
        [operator, value] in [:'&&', false] | [:'||', true]
      end
    end
  end
end
