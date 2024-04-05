# frozen_string_literal: true

module RuPkl
  module Node
    module ValueCommon
      def initialize(value, position)
        @value = value
        @position = position
      end

      attr_reader :value
      attr_reader :position

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
