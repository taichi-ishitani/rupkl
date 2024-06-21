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
        result = value.finite? && value.ceil || value
        self.class.new(parent, result, position)
      end

      define_builtin_property(:floor) do
        result = value.finite? && value.floor || value
        self.class.new(parent, result, position)
      end

      define_builtin_property(:isPositive) do
        result = value.zero? || value.positive?
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:isFinite) do
        Boolean.new(parent, value.finite?, position)
      end

      define_builtin_property(:isInfinite) do
        result = value.infinite? && true || false
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:isNaN) do
        result = !value.integer? && value.nan?
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:isNonZero) do
        Boolean.new(parent, !value.zero?, position)
      end

      define_builtin_method(:toString) do
        String.new(parent, value.to_s, nil, position)
      end

      define_builtin_method(:round) do
        result = value.finite? && value.round || value
        self.class.new(parent, result, position)
      end

      define_builtin_method(:truncate) do
        result = value.finite? && value.truncate || value
        self.class.new(parent, result, position)
      end
    end

    class Int < Number
      def initialize(parent, value, position)
        super(parent, value.to_i, position)
      end

      uninstantiable_class

      define_builtin_property(:isEven) do
        Boolean.new(parent, value.even?, position)
      end

      define_builtin_property(:isOdd) do
        Boolean.new(parent, value.odd?, position)
      end

      define_builtin_property(:inv) do
        self.class.new(parent, ~value, position)
      end
    end

    class Float < Number
      def initialize(parent, value, position)
        super(parent, value.to_f, position)
      end

      uninstantiable_class
    end
  end
end
