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

      def methods
        @body&.methods
      end

      def classes
        @body&.classes
      end

      def evaluate(context = nil)
        evaluate_lazily(context)
        super
      end

      private

      def properties_not_allowed?
        false
      end
    end
  end
end
