# frozen_string_literal: true

module RuPkl
  module Node
    class String
      include ValueCommon

      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions

      def evaluate(_scopes)
        s = value || portions&.join || ''
        self.class.new(s, nil, position)
      end

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end
    end
  end
end
