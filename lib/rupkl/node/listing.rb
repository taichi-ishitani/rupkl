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

      define_builtin_property(:isEmpty) do
        result = elements.nil? || elements.empty?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:length) do
        result = elements&.size || 0
        Int.new(self, result, position)
      end

      define_builtin_property(:isDistinct) do
        result =
          elements.nil? ||
          elements.all? { |lhs| elements.one? { |rhs| rhs == lhs } }
        Boolean.new(self, result || elements.nil?, position)
      end

      define_builtin_property(:distinct) do
        result =
          elements
            &.each_with_object([]) { |e, l| l << e unless l.include?(e) }
        body = ObjectBody.new(nil, result, position)
        Listing.new(self, body, position)
      end

      define_builtin_method(:join, separator: String) do |args, parent, position|
        result =
          elements
            &.map { _1.value.to_string }
            &.join(args[:separator].value)
        String.new(parent, result || '', nil, position)
      end

      private

      def elements_not_allowed?
        false
      end
    end
  end
end
