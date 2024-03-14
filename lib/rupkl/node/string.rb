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
    end
  end
end
