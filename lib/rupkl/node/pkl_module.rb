# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule
      include StructCommon

      def properties
        @body&.properties
      end
    end
  end
end
