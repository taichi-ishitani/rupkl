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

      define_builtin_property(:isEmpty) do
        result = entries.nil? || entries.empty?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:length) do
        result = entries&.size || 0
        Int.new(self, result, position)
      end

      define_builtin_method(:containsKey, key: Any) do |key|
        result = find_entry(key) && true || false
        Boolean.new(nil, result, nil)
      end

      define_builtin_method(:getOrNull, key: Any) do |key|
        find_entry(key) || Null.new(nil, nil)
      end

      private

      def entries_not_allowed?
        false
      end
    end
  end
end
