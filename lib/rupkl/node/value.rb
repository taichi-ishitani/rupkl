# frozen_string_literal: true

module RuPkl
  module Node
    class ValueBase
      def initialize(value, position)
        @value = value
        @position = position
      end

      attr_reader :value
      attr_reader :position
    end

    class Boolean < ValueBase
    end

    class Integer < ValueBase
    end

    class String < ValueBase
      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions
    end
  end
end
