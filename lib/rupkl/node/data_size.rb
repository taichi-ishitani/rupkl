# frozen_string_literal: true

module RuPkl
  module Node
    class DataSize < Any
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
        value.to_ruby(context) * unit_factor
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        "#{value.to_pkl_string(context)}.#{unit}"
      end

      private

      def unit_factor
        {
          b: 1000**0,
          kb: 1000**1, mb: 1000**2, gb: 1000**3,
          tb: 1000**4, pb: 1000**5,
          kib: 1024**1, mib: 1024**2, gib: 1024**3,
          tib: 1024**4, pib: 1024**5
        }[unit]
      end
    end
  end
end
