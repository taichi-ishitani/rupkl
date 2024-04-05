# frozen_string_literal: true

module RuPkl
  module Node
    class Dynamic
      include StructCommon

      def initialize(body, position)
        @body = body
        @position = position
      end

      attr_reader :position

      def properties
        @body.properties
      end

      def entries
        @body.entries
      end

      def elements
        @body.elements
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(properties, other.properties, false) &&
          match_members?(entries, other.entries, false) &&
          match_members?(elements, other.elements, true)
      end

      def undefined_operator?(operator)
        [:[], :==, :'!='].none?(operator)
      end

      def find_by_key(key)
        find_entry(key) || find_element(key)
      end

      private

      def find_entry(key)
        entries
          &.find { _1.key == key }
          &.then(&:value)
      end

      def find_element(index)
        return nil unless elements
        return nil unless index.value.is_a?(::Integer)

        elements
          .find.with_index { |_, i| i == index.value }
      end
    end
  end
end
