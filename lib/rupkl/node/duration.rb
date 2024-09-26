# frozen_string_literal: true

module RuPkl
  module Node
    class Duration < Any
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
        value.to_ruby(context) * UNIT_FACTOR[unit]
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        "#{value.to_pkl_string(context)}.#{unit}"
      end

      def u_op_minus(position)
        Duration.new(nil, value.u_op_minus(position), unit, position)
      end

      def ==(other)
        other.is_a?(Duration) &&
          begin
            l = calc_second(self)
            r = calc_second(other)
            l.value == r.value
          end
      end

      [:b_op_lt, :b_op_gt, :b_op_le, :b_op_ge].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_lt(r_operand, position)
          #   l = calc_second(self)
          #   r = calc_second(r_operand)
          #   l.b_op_lt(r, position)
          # end
          def #{method_name}(r_operand, position)
            l = calc_second(self)
            r = calc_second(r_operand)
            l.#{method_name}(r, position)
          end
        M
      end

      [:b_op_add, :b_op_sub].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_add(r_operand, position)
          #   l, r, u = align_unit(self, r_operand)
          #   result = l.b_op_add(r, position)
          #   Duration.new(nil, result, u, position)
          # end
          def #{method_name}(r_operand, position)
            l, r, u = align_unit(self, r_operand)
            result = l.#{method_name}(r, position)
            Duration.new(nil, result, u, position)
          end
        M
      end

      [:b_op_mul, :b_op_rem, :b_op_exp].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_mul(r_operand, position)
          #   result = value.b_op_mul(r_operand, position)
          #   Duration.new(nil, result, unit, position)
          # end
          def #{method_name}(r_operand, position)
            result = value.#{method_name}(r_operand, position)
            Duration.new(nil, result, unit, position)
          end
        M
      end

      [:b_op_div, :b_op_truncating_div].each do |method_name|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_div(r_operand, position)
          #   if r_operand.is_a?(Duration)
          #     l = calc_second(self)
          #     r = calc_second(r_operand)
          #     l.b_op_div(r, position)
          #   else
          #     result = value.b_op_div(r_operand, position)
          #     Duration.new(nil, result, unit, position)
          #   end
          # end
          def #{method_name}(r_operand, position)
            if r_operand.is_a?(Duration)
              l = calc_second(self)
              r = calc_second(r_operand)
              l.#{method_name}(r, position)
            else
              result = value.#{method_name}(r_operand, position)
              Duration.new(nil, result, unit, position)
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

      define_builtin_property(:isoString) do
        unless value.value.finite?
          message = "cannot convert duration '#{to_string(nil)}' to ISO 8601 duration"
          raise EvaluationError.new(message, position)
        end

        String.new(self, iso8601_string, nil, position)
      end

      define_builtin_method(
        :isBetween, first: Duration, last: Duration
      ) do |args, parent, position|
        r = calc_second(self)
        f = calc_second(args[:first])
        l = calc_second(args[:last])
        r.execute_builtin_method(:isBetween, { first: f, last: l }, parent, position)
      end

      define_builtin_method(:toUnit, unit: String) do |args, parent, position|
        unit = unit_symbol(args[:unit], position)
        value = convert_unit(self, unit, position)
        Duration.new(parent, value, unit, position)
      end

      private

      UNIT_FACTOR = {
        ns: 10.0**-9, us: 10.0**-6, ms: 10.0**-3,
        s: 1, min: 60, h: 60 * 60, d: 24 * 60 * 60
      }.freeze

      def unit_factor(unit)
        factor = UNIT_FACTOR[unit]
        if factor >= 1
          Int.new(nil, factor, nil)
        else
          Float.new(nil, factor, nil)
        end
      end

      def defined_operator?(operator)
        [:[], :'!@', :'&&', :'||'].none?(operator)
      end

      def valid_r_operand?(operator, operand)
        case operator
        when :*, :%, :** then operand in Number
        when :/, :'~/' then operand in Number | Duration
        else super
        end
      end

      def calc_second(duration)
        factor = unit_factor(duration.unit)
        duration.value.b_op_mul(factor, nil)
      end

      def align_unit(l_operand, r_operand)
        unit =
          if UNIT_FACTOR[l_operand.unit] >= UNIT_FACTOR[r_operand.unit]
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

      def convert_unit(duration, unit, position)
        return duration.value if duration.unit == unit

        second = calc_second(duration)
        result = second.b_op_div(unit_factor(unit), position)
        if result.value.to_i == result.value
          Int.new(nil, result.value, position)
        else
          result
        end
      end

      def iso8601_string
        return 'PT0S' if value.value.zero?

        parts = value.value.negative? && ['-PT'] || ['PT']
        iso8601_elements.each do |unit, n|
          parts << format_iso8601_element(unit, n)
        end

        parts.join
      end

      def iso8601_elements
        result, _ =
          [:h, :min, :s]
            .inject([{}, calc_second(self).value.abs]) do |(elements, sec), unit|
              q, r =
                if unit == :s
                  sec
                else
                  sec.divmod(UNIT_FACTOR[unit])
                end
              elements[unit] = q if q.positive?

              [elements, r]
            end

        result
      end

      def format_iso8601_element(unit, value)
        s =
          if unit != :s || value.to_i == value
            value
          else
            format('%.12f', value).sub(/0+\Z/, '')
          end
        "#{s}#{unit[0].upcase}"
      end

      def unit_symbol(string, position)
        symbol = string.value.to_sym
        return symbol if UNIT_FACTOR.key?(symbol)

        message =
          'expected value of type ' \
          '"ns"|"us"|"ms"|"s"|"min"|"h"|"d", ' \
          "but got #{string.to_pkl_string(nil)}"
        raise EvaluationError.new(message, position)
      end
    end
  end
end
