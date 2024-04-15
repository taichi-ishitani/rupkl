# frozen_string_literal: true

module RuPkl
  module Node
    class Mapping < Any
      include StructCommon

      def entries
        @body&.entries
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(entries, other.entries, false)
      end

      def find_by_key(key)
        find_entry(key)
      end

      private

      def entries_not_allowed?
        false
      end
    end
  end
end
