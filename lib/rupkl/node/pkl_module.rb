# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule
      include StructCommon

      def initialize(body, position)
        @body = body
        @position = position
      end

      attr_reader :position

      def properties
        @body&.properties
      end
    end
  end
end
