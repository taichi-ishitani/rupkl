# frozen_string_literal: true

module RuPkl
  module Node
    module ValueCommon
      include NodeCommon

      def initialize(value, position)
        super(position)
        @value = value
      end

      attr_reader :value

      def evaluate(_context)
        self
      end

      def evaluate_lazily(_context)
        self
      end

      def to_ruby(context)
        evaluate(context).value
      end

      def to_string(context)
        to_ruby(context).to_s
      end

      def to_pkl_string(context)
        to_string(context)
      end

      def ==(other)
        other.instance_of?(self.class) && value == other.value
      end

      def coerce(_operator, r_operand)
        [value, r_operand.value]
      end
    end
  end
end
