# frozen_string_literal: true

module RuPkl
  module Node
    class Dynamic < Any
      include StructCommon

      def properties
        @body&.properties(visibility: :object)
      end

      def entries
        @body&.entries
      end

      def elements
        @body&.elements
      end

      def to_ruby(context = nil)
        to_pkl_object(context)
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(properties, other.properties, false) &&
          match_members?(entries, other.entries, false) &&
          match_members?(elements, other.elements, true)
      end

      def find_by_key(key)
        (find_entry(key) || find_element(key))&.value
      end

      define_builtin_method(:length) do |_, parent, position|
        result = elements&.size || 0
        Int.new(parent, result, position)
      end

      define_builtin_method(:hasProperty, name: String) do |args, parent, position|
        name = args[:name].value.to_sym
        result = find_property(name) && true || false
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:getProperty, name: String) do |args, _, position|
        name = args[:name].value.to_sym
        find_property(name)&.value ||
          begin
            m = "cannot find property '#{name}'"
            raise EvaluationError.new(m, position)
          end
      end

      define_builtin_method(:getPropertyOrNull, name: String) do |args, parent, position|
        name = args[:name].value.to_sym
        find_property(name)&.value || Null.new(parent, position)
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
