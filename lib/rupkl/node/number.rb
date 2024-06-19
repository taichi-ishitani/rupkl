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

      define_builtin_property(:sign) do
        result =
          case value
          when :positive?.to_proc then 1
          when :negative?.to_proc then -1
          else value
          end
        self.class.new(parent, result, position)
      end

      define_builtin_property(:abs) do
        self.class.new(parent, value.abs, position)
      end

      define_builtin_property(:ceil) do
        self.class.new(parent, value.ceil, position)
      end

      define_builtin_property(:floor) do
        self.class.new(parent, value.floor, position)
      end

      define_builtin_property(:isPositive) do
        result = value.zero? || value.positive?
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:isNonZero) do
        Boolean.new(parent, !value.zero?, position)
      end
    end

    class Int < Number
      def initialize(parent, value, position)
        super(parent, value.to_i, position)
      end

      uninstantiable_class
    end

    class Float < Number
      def initialize(parent, value, position)
        super(parent, value.to_f, position)
      end

      uninstantiable_class
    end
  end
end
