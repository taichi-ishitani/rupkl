# frozen_string_literal: true

module RuPkl
  module Node
    class DataSize < Any
      include Operatable

      uninstantiable_class

      def initialize(parent, value, unit, position)
        super(parent, value, position)
        @unit = unit
      end

      attr_reader :unit

      def value
        @children[0]
      end

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        value.to_ruby(context) * unit_factor(unit)
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        "#{value.to_pkl_string(context)}.#{unit}"
      end

      def u_op_minus(position)
        DataSize.new(nil, value.u_op_minus(position), unit, position)
      end

      [
        :b_op_lt, :b_op_gt,
        :b_op_le, :b_op_ge,
        :b_op_eq, :b_op_ne
      ].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_lt(r_operand, position)
          # l = calc_byte_size(self)
          # r = calc_byte_size(r_operand)
          # l.b_op_lt(r, position)
          # end
          def #{method_name}(r_operand, position)
            l = calc_byte_size(self)
            r = calc_byte_size(r_operand)
            l.#{method_name}(r, position)
          end
        M
      end

      [:b_op_add, :b_op_sub].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_add(r_operand, position)
          #   l, r, u = align_unit(self, r_operand)
          #   result = l.b_op_add(r, position)
          #   DataSize.new(nil, result, u, position)
          # end
          def #{method_name}(r_operand, position)
            l, r, u = align_unit(self, r_operand)
            result = l.#{method_name}(r, position)
            DataSize.new(nil, result, u, position)
          end
        M
      end

      [:b_op_mul, :b_op_rem, :b_op_exp].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_mul(r_operand, position)
          #   result = value.b_op_mul(r_operand, position)
          #   DataSize.new(nil, result, unit, position)
          # end
          def #{method_name}(r_operand, position)
            result = value.#{method_name}(r_operand, position)
            DataSize.new(nil, result, unit, position)
          end
        M
      end

      [:b_op_div, :b_op_truncating_div].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_div(r_operand, position)
          #   if r_operand.is_a?(DataSize)
          #     l = calc_byte_size(self)
          #     r = calc_byte_size(r_operand)
          #     l.b_op_div(r, position)
          #   else
          #     result = value.b_op_div(r_operand, position)
          #     DataSize.new(nil, result, unit, position)
          #   end
          # end
          def #{method_name}(r_operand, position)
            if r_operand.is_a?(DataSize)
              l = calc_byte_size(self)
              r = calc_byte_size(r_operand)
              l.#{method_name}(r, position)
            else
              result = value.#{method_name}(r_operand, position)
              DataSize.new(nil, result, unit, position)
            end
          end
        M
      end

      define_builtin_property(:value) do
        value
      end

      define_builtin_property(:unit) do
        String.new(self, unit.to_s, nil, position)
      end

      define_builtin_property(:isPositive) do
        result = value.value.zero? || value.value.positive?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:isBinaryUnit) do
        result = [:b, :kib, :mib, :gib, :tib, :pib].include?(unit)
        Boolean.new(self, result, position)
      end

      define_builtin_property(:isDecimalUnit) do
        result = [:b, :kb, :mb, :gb, :tb, :pb].include?(unit)
        Boolean.new(self, result, position)
      end

      define_builtin_method(
        :isBetween, first: DataSize, last: DataSize
      ) do |args, parent, position|
        r = calc_byte_size(self)
        f = calc_byte_size(args[:first])
        l = calc_byte_size(args[:last])
        r.execute_builtin_method(:isBetween, { first: f, last: l }, parent, position)
      end

      define_builtin_method(:toUnit, unit: String) do |args, parent, position|
        unit = unit_symbol(args[:unit], position)
        value = convert_unit(self, unit, position)
        DataSize.new(parent, value, unit, position)
      end

      define_builtin_method(:toBinaryUnit) do |_args, parent, position|
        if (unit = to_binary_unit)
          value = convert_unit(self, unit, position)
          DataSize.new(parent, value, unit, position)
        else
          self
        end
      end

      define_builtin_method(:toDecimalUnit) do |_args, parent, position|
        if (unit = to_decimal_unit)
          value = convert_unit(self, unit, position)
          DataSize.new(parent, value, unit, position)
        else
          self
        end
      end

      private

      UNIT_FACTOR = {
        b: 1000**0,
        kb: 1000**1, mb: 1000**2, gb: 1000**3,
        tb: 1000**4, pb: 1000**5,
        kib: 1024**1, mib: 1024**2, gib: 1024**3,
        tib: 1024**4, pib: 1024**5
      }.freeze

      def unit_factor(unit)
        UNIT_FACTOR[unit]
      end

      def defined_operator?(operator)
        [:[], :'!@', :'&&', :'||'].none?(operator)
      end

      def valid_r_operand?(operator, operand)
        case operator
        when :*, :%, :** then operand in Number
        when :/, :'~/' then operand in Number | DataSize
        else super
        end
      end

      def calc_byte_size(data_size)
        factor = Int.new(nil, unit_factor(data_size.unit), nil)
        data_size.value.b_op_mul(factor, nil)
      end

      def align_unit(l_operand, r_operand)
        unit =
          if unit_factor(l_operand.unit) >= unit_factor(r_operand.unit)
            l_operand.unit
          else
            r_operand.unit
          end

        [
          convert_unit(l_operand, unit, position),
          convert_unit(r_operand, unit, position),
          unit
        ]
      end

      def convert_unit(data_size, unit, position)
        return data_size.value if data_size.unit == unit

        byte_size = calc_byte_size(data_size)
        factor = Int.new(nil, unit_factor(unit), nil)
        if (byte_size.value % factor.value).zero?
          byte_size.b_op_truncating_div(factor, position)
        else
          byte_size.b_op_div(factor, position)
        end
      end

      def unit_symbol(string, position)
        symbol = string.value.to_sym
        return symbol if UNIT_FACTOR.key?(symbol)

        message =
          'expected value of type ' \
          '"b"|"kb"|"kib"|"mb"|"mib"|"gb"|"gib"|"tb"|"tib"|"pb"|"pib", ' \
          "but got #{string.to_pkl_string(nil)}"
        raise EvaluationError.new(message, position)
      end

      def to_binary_unit
        {
          kb: :kib, mb: :mib, gb: :gib,
          tb: :tib, pb: :pib
        }[unit]
      end

      def to_decimal_unit
        {
          kib: :kb, mib: :mb, gib: :gb,
          tib: :tb, pib: :pb
        }[unit]
      end
    end
  end
end
