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
          # l = calc_byte_size(value, unit)
          # r = calc_byte_size(r_operand.value, r_operand.unit)
          # l.b_op_lt(r, position)
          # end
          def #{method_name}(r_operand, position)
            l = calc_byte_size(value, unit)
            r = calc_byte_size(r_operand.value, r_operand.unit)
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
          #     l = calc_byte_size(value, unit)
          #     r = calc_byte_size(r_operand.value, r_operand.unit)
          #     l.b_op_div(r, position)
          #   else
          #     result = value.b_op_div(r_operand, position)
          #     DataSize.new(nil, result, unit, position)
          #   end
          # end
          def #{method_name}(r_operand, position)
            if r_operand.is_a?(DataSize)
              l = calc_byte_size(value, unit)
              r = calc_byte_size(r_operand.value, r_operand.unit)
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

      private

      def unit_factor(unit)
        {
          b: 1000**0,
          kb: 1000**1, mb: 1000**2, gb: 1000**3,
          tb: 1000**4, pb: 1000**5,
          kib: 1024**1, mib: 1024**2, gib: 1024**3,
          tib: 1024**4, pib: 1024**5
        }[unit]
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

      def calc_byte_size(value, unit)
        factor = Int.new(nil, unit_factor(unit), nil)
        value.b_op_mul(factor, nil)
      end

      def align_unit(l_operand, r_operand)
        l_factor = unit_factor(l_operand.unit)
        r_factor = unit_factor(r_operand.unit)
        if l_factor > r_factor
          [l_operand.value, convert_unit(r_operand, r_factor, l_factor), l_operand.unit]
        elsif l_factor < r_factor
          [convert_unit(l_operand, l_factor, r_factor), r_operand.value, r_operand.unit]
        else
          [l_operand.value, r_operand.value, l_operand.unit]
        end
      end

      def convert_unit(data_size, factor_own, factor_other)
        ratio =
          if (factor_other % factor_own).zero?
            Int.new(nil, factor_other / factor_own, nil)
          else
            Float.new(nil, factor_other.to_f / factor_own, nil)
          end
        data_size.value.b_op_div(ratio, nil)
      end
    end
  end
end
