# frozen_string_literal: true

module RuPkl
  module Node
    module MemberFinder
      def property(name)
        value = find_property(name)
        return value if value

        super if self.class <= Any
      end

      private

      def find_property(name)
        return unless respond_to?(:properties)

        properties
          &.find { _1.name == name }
          &.value
      end

      def find_entry(key)
        return unless respond_to?(:entries)

        entries
          &.find { _1.key == key }
          &.then(&:value)
      end

      def find_element(index)
        return unless respond_to?(:elements)
        return unless elements
        return unless index.value.is_a?(::Integer)

        elements
          .find.with_index { |_, i| i == index.value }
          &.then(&:value)
      end
    end
  end
end
