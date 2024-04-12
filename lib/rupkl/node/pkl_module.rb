# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule < Any
      include StructCommon

      abstract_class
      klass_name :Module

      def properties
        @body&.properties
      end

      def classes
        @body&.classes
      end
    end
  end
end
