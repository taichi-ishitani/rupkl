# frozen_string_literal: true

module RuPkl
  module Node
    class Number < Any
      include ValueCommon
      include Operatable

      abstract_class
      uninstantiable_class

      def u_op_minus(position)
        self.class.new(nil, -value, position)
      end

      {
        b_op_exp: [:**, false], b_op_div: [:/, false],
        b_op_truncating_div: [:/, true], b_op_rem: [:%, false],
        b_op_add: [:+, false], b_op_sub: [:-, false]
      }.each do |method_name, (op, result_int)|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_exp(r_operand, position)
          #   b_op_arithmetic(:'**', r_operand, false, position)
          # end
          def #{method_name}(r_operand, position)
            b_op_arithmetic(:'#{op}', r_operand, #{result_int}, position)
          end
        M
      end

      def b_op_mul(r_operand, position)
        case r_operand
        when Number then b_op_arithmetic(:*, r_operand, false, position)
        else r_operand.b_op_mul(self, position)
        end
      end

      {
        b_op_lt: :<, b_op_gt: :>,
        b_op_le: :<=, b_op_ge: :>=,
        b_op_eq: :==, b_op_ne: :'!='
      }.each do |method_name, op|
        class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def b_op_lt(r_operand, position)
          #   l, r = coerce(:'<', r_operand)
          #   result = l < r
          #   Boolean.new(nil, result, position)
          # end
          def #{method_name}(r_operand, position)
            l, r = coerce(:'#{op}', r_operand)
            result = l #{op} r
            Boolean.new(nil, result, position)
          end
        M
      end

      define_builtin_property(:sign) do
        result =
          case value
          when :positive?.to_proc then 1
          when :negative?.to_proc then -1
          else value
          end
        self.class.new(self, result, position)
      end

      [
        :b, :kb, :kib, :mb, :mib, :gb, :gib, :tb, :tib, :pb, :pib
      ].each do |unit|
        class_eval(<<~P, __FILE__, __LINE__ + 1)
          # define_builtin_property(:b) do
          #   DataSize.new(self, self, :b, position)
          # end
          define_builtin_property(:#{unit}) do
            DataSize.new(self, self, :#{unit}, position)
          end
        P
      end

      [:ns, :us, :ms, :s, :min, :h, :d].each do |unit|
        class_eval(<<~P, __FILE__, __LINE__ + 1)
          # define_builtin_property(:ns) do
          #   Duration.new(self, self, :ns, position)
          # end
          define_builtin_property(:#{unit}) do
            Duration.new(self, self, :#{unit}, position)
          end
        P
      end

      define_builtin_property(:abs) do
        self.class.new(self, value.abs, position)
      end

      define_builtin_property(:ceil) do
        result = value.finite? && value.ceil || value
        self.class.new(self, result, position)
      end

      define_builtin_property(:floor) do
        result = value.finite? && value.floor || value
        self.class.new(self, result, position)
      end

      define_builtin_property(:isPositive) do
        result = value.zero? || value.positive?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:isFinite) do
        Boolean.new(self, value.finite?, position)
      end

      define_builtin_property(:isInfinite) do
        result = value.infinite? && true || false
        Boolean.new(self, result, position)
      end

      define_builtin_property(:isNaN) do
        result = !value.integer? && value.nan?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:isNonZero) do
        Boolean.new(self, !value.zero?, position)
      end

      define_builtin_method(:toString) do |_, parent, position|
        String.new(parent, value.to_s, nil, position)
      end

      define_builtin_method(:toInt) do |_, parent, position|
        Int.new(parent, value.to_i, position)
      end

      define_builtin_method(:toFloat) do |_, parent, position|
        Float.new(parent, value.to_f, position)
      end

      define_builtin_method(:round) do |_, parent, position|
        result = value.finite? && value.round || value
        self.class.new(parent, result, position)
      end

      define_builtin_method(:truncate) do |_, parent, position|
        result = value.finite? && value.truncate || value
        self.class.new(parent, result, position)
      end

      define_builtin_method(
        :isBetween, first: Number, last: Number
      ) do |args, parent, position|
        f = args[:first].value
        l = args[:last].value
        result =
          [f, l, value].all? { _1.finite? || _1.infinite? } &&
          (f..l).include?(value)
        Boolean.new(parent, result, position)
      end

      private

      def defined_operator?(operator)
        [:[], :'!@', :'&&', :'||'].none?(operator)
      end

      def valid_r_operand?(operator, operand)
        case operator
        when :* then operand in Number | DataSize | Duration
        else operand in Number
        end
      end

      def coerce(operator, r_operand)
        if force_float?(operator, r_operand)
          [value.to_f, r_operand.value.to_f]
        else
          [value.to_i, r_operand.value.to_i]
        end
      end

      def force_float?(operator, r_operand)
        operator == :/ || [self, r_operand].any?(Float)
      end

      def b_op_arithmetic(operator, r_operand, result_int, position)
        l, r = coerce(operator, r_operand)
        result = l.__send__(operator, r)
        if result_int || result.integer?
          Int.new(nil, result, position)
        else
          Float.new(nil, result, position)
        end
      end
    end

    class Int < Number
      def initialize(parent, value, position)
        super(parent, value.to_i, position)
      end

      uninstantiable_class

      define_builtin_property(:isEven) do
        Boolean.new(self, value.even?, position)
      end

      define_builtin_property(:isOdd) do
        Boolean.new(self, value.odd?, position)
      end

      define_builtin_property(:inv) do
        self.class.new(self, ~value, position)
      end

      define_builtin_method(:shl, n: Int) do |args, parent, position|
        result = value << args[:n].value
        self.class.new(parent, result, position)
      end

      define_builtin_method(:shr, n: Int) do |args, parent, position|
        result = value >> args[:n].value
        self.class.new(parent, result, position)
      end

      define_builtin_method(:ushr, n: Int) do |args, parent, position|
        result =
          if value.negative?
            mask = (1 << 63) - 1
            args[:n].value.times.inject(value) { |v, _| (v >> 1) & mask }
          else
            value >> args[:n].value
          end
        self.class.new(parent, result, position)
      end

      define_builtin_method(:and, n: Int) do |args, parent, position|
        self.class.new(parent, value & args[:n].value, position)
      end

      define_builtin_method(:or, n: Int) do |args, parent, position|
        self.class.new(parent, value | args[:n].value, position)
      end

      define_builtin_method(:xor, n: Int) do |args, parent, position|
        self.class.new(parent, value ^ args[:n].value, position)
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
