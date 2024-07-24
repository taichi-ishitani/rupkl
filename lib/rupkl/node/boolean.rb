# frozen_string_literal: true

module RuPkl
  module Node
    class Boolean < Any
      include ValueCommon

      uninstantiable_class

      def undefined_operator?(operator)
        [:!, :==, :'!=', :'&&', :'||'].none?(operator)
      end

      def short_circuit?(operator)
        [operator, value] in [:'&&', false] | [:'||', true]
      end

      define_builtin_method(:xor, other: Boolean) do |args, parent, position|
        result = value ^ args[:other].value
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:implies, other: Boolean) do |args, parent, position|
        result = !value || args[:other].value
        Boolean.new(parent, result, position)
      end
    end
  end
end
