# frozen_string_literal: true

module RuPkl
  module Node
    class IntSeq < Any
      uninstantiable_class

      def initialize(parent, start, last, step, position)
        super(parent, *[start, last, step].compact, position)
      end

      def start
        children[0]
      end

      def last
        children[1]
      end

      alias_method :end, :last

      def step
        children[2]
      end

      def evaluate(_context = nil)
        self
      end

      def to_ruby(_context = nil)
        to_array(self)
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        start_value, last_value, _step_value = children.map { _1.to_pkl_string(context) }
        "IntSeq(#{start_value}, #{last_value})"
      end

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      def ==(other)
        other.is_a?(self.class) &&
          to_array(self) == to_array(other)
      end

      private

      def to_array(intseq)
        start_value, last_value, step_value = intseq.children.map(&:value)
        Range.new(start_value, last_value).step(step_value || 1).to_a
      end
    end
  end
end
