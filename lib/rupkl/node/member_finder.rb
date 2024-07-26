# frozen_string_literal: true

module RuPkl
  module Node
    module MemberFinder
      def property(name)
        value = find_property(name)&.value
        return value if value

        super if self.class <= Any
      end

      def pkl_method(name)
        method = find_pkl_method(name)
        return method if method

        super if self.class <= Any
      end

      private

      def find_property(name)
        return unless respond_to?(:properties)

        properties&.find { _1.name == name }
      end

      def find_entry(key)
        return unless respond_to?(:entries)

        entries&.find { _1.key == key }
      end

      def find_element(index)
        return unless respond_to?(:elements)
        return unless elements
        return unless index.value.is_a?(::Integer)

        elements.find.with_index { |_, i| i == index.value }
      end

      def find_pkl_method(name)
        return unless respond_to?(:pkl_methods)

        pkl_methods&.find { _1.name == name }
      end
    end
  end
end
