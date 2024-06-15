# frozen_string_literal: true

module RuPkl
  module Node
    class DeclaredType
      include TypeCommon

      def initialize(parent, type, position)
        super(parent, *type, position)
        @type = type
      end

      attr_reader :type

      def find_class(context)
        find_type(type, context)
      end

      def to_s
        type.last.id.to_s
      end

      private

      def match_type?(klass, context)
        rhs = klass
        lhs = find_class(context)
        rhs <= lhs
      end
    end
  end
end
