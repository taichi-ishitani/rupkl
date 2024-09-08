# frozen_string_literal: true

module RuPkl
  module Node
    class Regex < Any
      def initialize(parent, pattern, position)
        super
        @pattern = Regexp.new(pattern.value)
      end

      attr_reader :pattern

      def evaluate(_context = nil)
        self
      end

      def to_ruby(_context = nil)
        pattern
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        source_string = source.to_pkl_string(context)
        "Regex(#{source_string})"
      end

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      def ==(other)
        other.is_a?(self.class) && pattern == other.pattern
      end

      define_builtin_property(:pattern) do
        source
      end

      define_builtin_property(:groupCount) do
        Int.new(nil, group_count, position)
      end

      private

      def source
        @children[0]
      end

      def group_count
        Regexp::Parser
          .parse(pattern)
          .each_expression.count { |exp, _| exp.capturing? }
      end
    end
  end
end
