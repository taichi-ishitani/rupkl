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
        value = portions&.join || ''
        self.class.new(value, nil, position)
      end
    end
  end
end
