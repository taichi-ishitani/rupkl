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

      def pkl_methods
        @body&.pkl_methods
      end

      def pkl_classes
        @body&.pkl_classes
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
