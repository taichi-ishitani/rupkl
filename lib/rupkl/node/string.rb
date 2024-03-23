# frozen_string_literal: true

module RuPkl
  module Node
    class String
      include ValueCommon
      include Operatable

      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions

      def evaluate(_scopes)
        s = value || portions&.join || ''
        self.class.new(s, nil, position)
      end

      private

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end

      def coerce(operator, l_operand, r_operand)
        [operator, l_operand.value, r_operand.value]
      end
    end
  end
end
