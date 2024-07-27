# frozen_string_literal: true

module RuPkl
  module Node
    class List < Collection
      include MemberFinder
      undef_method :pkl_method

      uninstantiable_class

      def initialize(parent, elements, position)
        super(parent, *elements, position)
      end

      alias_method :elements, :children

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        objects = elements&.map { _1.to_ruby(context) }
        PklObject.new(nil, nil, objects)
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        element_string =
          elements
            &.map { _1.to_pkl_string(context) }
            &.join(', ')
        "List(#{element_string})"
      end

      def undefined_operator?(operator)
        [:[], :==, :'!=', :+].none?(operator)
      end

      def invalid_r_operand?(_operator, operand)
        !operand.is_a?(List)
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      def convert_operator(operator)
        case operator
        when :+ then :plus_op
        end
      end

      def plus_op(operand, parent, position)
        result =
          if elements && operand.elements
            elements + operand.elements
          else
            elements || operand.elements
          end
        self.class.new(parent, result, position)
      end

      def ==(other)
        other.instance_of?(self.class) && elements == other.elements
      end

      def find_by_key(key)
        find_element(key)
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
        elements&.first || raise_wrong_list_size_error
      end

      define_builtin_property(:firstOrNull) do
        elements&.first || Null.new(parent, position)
      end

      define_builtin_property(:rest) do
        if (result = elements&.[](1..))
          List.new(parent, result, position)
        else
          raise_wrong_list_size_error
        end
      end

      define_builtin_property(:restOrNull) do
        if (result = elements&.[](1..))
          List.new(parent, result, position)
        else
          Null.new(parent, position)
        end
      end

      define_builtin_property(:last) do
        elements&.last || raise_wrong_list_size_error
      end

      define_builtin_property(:lastOrNull) do
        elements&.last || Null.new(parent, position)
      end

      define_builtin_property(:single) do
        size = elements&.size || 0
        size == 1 && elements.first ||
          raise_wrong_list_size_error { 'expected a single-element list' }
      end

      define_builtin_property(:singleOrNull) do
        size = elements&.size || 0
        size == 1 && elements.first || Null.new(parent, position)
      end

      define_builtin_property(:lastIndex) do
        result = (elements&.size || 0) - 1
        Int.new(parent, result, position)
      end

      define_builtin_property(:isDistinct) do
        result =
          elements.nil? ||
          elements.all? { |e| elements.one?(e) }
        Boolean.new(parent, result, position)
      end

      define_builtin_property(:distinct) do
        result =
          elements
            &.each_with_object([]) { |e, l| l << e unless l.include?(e) }
        List.new(parent, result, position)
      end

      private

      def raise_wrong_list_size_error
        message =
          if block_given?
            yield
          else
            'expected a non-empty list'
          end
        raise EvaluationError.new(message, position)
      end
    end
  end
end
