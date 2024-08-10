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
        start_value, last_value, step_value = children.map { _1.to_pkl_string(context) }
        if step && step.value != 1
          "IntSeq(#{start_value}, #{last_value}).step(#{step_value})"
        else
          "IntSeq(#{start_value}, #{last_value})"
        end
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

      define_builtin_property(:start) do
        Int.new(self, start.value, position)
      end

      define_builtin_property(:end) do
        Int.new(self, last.value, position)
      end

      define_builtin_property(:step) do
        Int.new(self, step&.value || 1, position)
      end

      define_builtin_method(:step, step: Int) do |args, parent, position|
        step = args[:step]
        if step.value.zero?
          message = "expected a non zero number, but got '#{step.value}'"
          raise EvaluationError.new(message, position)
        end

        IntSeq.new(parent, start, last, step, position)
      end

      private

      def to_array(intseq)
        start_value, last_value, step_value = intseq.children.map(&:value)
        Range.new(start_value, last_value).step(step_value || 1).to_a
      end
    end
  end
end
