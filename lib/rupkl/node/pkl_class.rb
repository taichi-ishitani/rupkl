# frozen_string_literal: true

module RuPkl
  module Node
    class PklClassProperty
      include PropertyEvaluator

      def initialize(name, value, objects, position)
        @name = name
        @value = value
        @objects = objects
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :objects
      attr_reader :position

      def evaluate(scopes)
        v = evaluate_property(value, objects, scopes)
        self.class.new(name, v, nil, position)
      end

      def to_ruby(scopes)
        [name.id, property_to_ruby(value, objects, scopes)]
      end
    end
  end
end
