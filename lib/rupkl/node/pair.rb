# frozen_string_literal: true

module RuPkl
  module Node
    class Pair < Any
      include Operatable

      uninstantiable_class

      def first
        @children[0]
      end

      def second
        @children[1]
      end

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        [first, second].map { _1.to_ruby(context) }
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        element_strings =
          [first, second].map { _1.to_pkl_string(context) }
        "Pair(#{element_strings[0]}, #{element_strings[1]})"
      end

      def ==(other)
        other.is_a?(self.class) &&
          first == other.first && second == other.second
      end

      define_builtin_property(:first) do
        first
      end

      define_builtin_property(:key) do
        first
      end

      define_builtin_property(:second) do
        second
      end

      define_builtin_property(:value) do
        second
      end
    end
  end
end
