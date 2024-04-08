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

      def evaluate(_scopes)
        self
      end

      def evaluate_lazily(_scopes)
        self
      end

      def to_ruby(scopes)
        evaluate(scopes).value
      end

      def to_string(scopes)
        to_ruby(scopes).to_s
      end

      def to_pkl_string(scopes)
        to_string(scopes)
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
