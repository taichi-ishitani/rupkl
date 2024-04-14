# frozen_string_literal: true

module RuPkl
  module Node
    class Dynamic < Any
      include StructCommon

      def properties
        @body&.properties
      end

      def entries
        @body&.entries
      end

      def elements
        @body&.elements
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(properties, other.properties, false) &&
          match_members?(entries, other.entries, false) &&
          match_members?(elements, other.elements, true)
      end

      def find_by_key(key)
        find_entry(key) || find_element(key)
      end

      private

      def properties_not_allowed?
        false
      end

      def entries_not_allowed?
        false
      end

      def elements_not_allowed?
        false
      end
    end
  end
end
