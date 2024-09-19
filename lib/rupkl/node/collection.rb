# frozen_string_literal: true

module RuPkl
  module Node
    class Collection < Any
      include Operatable

      abstract_class
      uninstantiable_class

      def initialize(parent, elements, position)
        super(parent, *elements, position)
      end

      alias_method :elements, :children

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        elements&.map { _1.to_ruby(context) } || []
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        element_string =
          elements
            &.map { _1.to_pkl_string(context) }
            &.join(', ')
        "#{self.class.basename}(#{element_string})"
      end

      def ==(other)
        other.instance_of?(self.class) && elements == other.elements
      end

      def b_op_add(r_operand, position)
        result =
          if elements && r_operand.elements
            elements + r_operand.elements
          else
            elements || r_operand.elements
          end
        self.class.new(nil, result, position)
      end

      define_builtin_property(:length) do
        result = elements&.size || 0
        Int.new(self, result, position)
      end

      define_builtin_property(:isEmpty) do
        result = elements.nil? || elements.empty?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:first) do
        elements&.first || raise_wrong_collection_size_error
      end

      define_builtin_property(:firstOrNull) do
        elements&.first || Null.new(parent, position)
      end

      define_builtin_property(:rest) do
        if (result = elements&.[](1..))
          self.class.new(parent, result, position)
        else
          raise_wrong_collection_size_error
        end
      end

      define_builtin_property(:restOrNull) do
        if (result = elements&.[](1..))
          self.class.new(parent, result, position)
        else
          Null.new(parent, position)
        end
      end

      define_builtin_property(:last) do
        elements&.last || raise_wrong_collection_size_error
      end

      define_builtin_property(:lastOrNull) do
        elements&.last || Null.new(parent, position)
      end

      define_builtin_property(:single) do
        size = elements&.size || 0
        size == 1 && elements.first ||
          raise_wrong_collection_size_error { 'expected a single-element collection' }
      end

      define_builtin_property(:singleOrNull) do
        size = elements&.size || 0
        size == 1 && elements.first || Null.new(parent, position)
      end

      define_builtin_property(:lastIndex) do
        result = (elements&.size || 0) - 1
        Int.new(parent, result, position)
      end

      private

      def remove_duplicate_elements(elements)
        elements
          &.each_with_object([]) { |e, a| a.include?(e) || (a << e) }
      end

      def raise_wrong_collection_size_error
        message =
          if block_given?
            yield
          else
            'expected a non-empty collection'
          end
        raise EvaluationError.new(message, position)
      end

      def valid_r_operand?(operator, operand)
        operand.is_a?(self.class) ||
          operator == :+ && (operand in List | Set)
      end
    end

    class List < Collection
      include MemberFinder
      undef_method :pkl_method

      uninstantiable_class

      def find_by_key(key)
        find_element(key)
      end

      define_builtin_property(:isDistinct) do
        result =
          elements.nil? ||
          elements.all? { |e| elements.one?(e) }
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:distinct) do
        result = remove_duplicate_elements(elements)
        List.new(parent, result, position)
      end

      private

      def defined_operator?(operator)
        [:[], :+].any?(operator)
      end
    end

    class Set < Collection
      uninstantiable_class

      def initialize(parent, elements, position)
        unique_elements = remove_duplicate_elements(elements)
        super(parent, unique_elements, position)
      end

      private

      def defined_operator?(operator)
        operator == :+
      end
    end
  end
end
