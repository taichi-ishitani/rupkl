# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule < Any
      include StructCommon

      abstract_class
      klass_name :Module

      def properties
        @body&.properties(visibility: :object)
      end

      def pkl_methods
        @body&.pkl_methods
      end

      def pkl_classes
        @body&.pkl_classes
      end

      def evaluate(context = nil)
        resolve_structure(context)
        super
      end

      def to_ruby(context = nil)
        to_pkl_object(context)
      end

      private

      def properties_not_allowed?
        false
      end
    end
  end
end
