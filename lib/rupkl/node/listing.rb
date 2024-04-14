# frozen_string_literal: true

module RuPkl
  module Node
    class Listing < Any
      include StructCommon

      def elements
        @body&.elements
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(elements, other.elements, true)
      end

      def find_by_key(key)
        find_element(key)
      end

      private

      def elements_not_allowed?
        false
      end
    end
  end
end
