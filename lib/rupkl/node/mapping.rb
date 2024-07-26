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
        find_entry(key)&.value
      end

      define_builtin_property(:isEmpty) do
        result = entries.nil? || entries.empty?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:length) do
        result = entries&.size || 0
        Int.new(self, result, position)
      end

      define_builtin_method(:containsKey, key: Any) do |args, parent, position|
        result = find_entry(args[:key]) && true || false
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:getOrNull, key: Any) do |args, parent, position|
        find_entry(args[:key])&.value || Null.new(parent, position)
      end

      private

      def entries_not_allowed?
        false
      end
    end
  end
end
