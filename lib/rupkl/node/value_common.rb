# frozen_string_literal: true

module RuPkl
  module Node
    module ValueCommon
      include NodeCommon

      def initialize(parent, value, position)
        super(parent, position)
        @value = value
      end

      attr_reader :value

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        evaluate(context).value
      end

      def to_string(context = nil)
        to_ruby(context).to_s
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, @value, position)
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
