# frozen_string_literal: true

module RuPkl
  module Node
    class Number < Any
      include ValueCommon

      def undefined_operator?(operator)
        [:[], :!, :'&&', :'||'].include?(operator)
      end

      def invalid_r_operand?(operand)
        !operand.is_a?(Number)
      end

      def coerce(operator, r_operand)
        if force_float?(operator, r_operand)
          [value.to_f, r_operand.value.to_f]
        else
          [value.to_i, r_operand.value.to_i]
        end
      end

      def force_float?(operator, r_operand)
        operator == :/ ||
          operator != :'~/' && [self, r_operand].any?(Float)
      end

      abstract_class
      uninstantiable_class
    end

    class Int < Number
      uninstantiable_class
    end

    class Float < Number
      uninstantiable_class
    end
  end
end
