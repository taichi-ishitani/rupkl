# frozen_string_literal: true

module RuPkl
  module Node
    class List < Collection
      include MemberFinder
      undef_method :property, :pkl_method

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
    end
  end
end
