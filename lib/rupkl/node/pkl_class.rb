# frozen_string_literal: true

module RuPkl
  module Node
    class PklClassProperty
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
        self.class.new(name, value.evaluate(scopes), nil, position)
      end

      def to_ruby(scopes)
        [name.to_ruby(scopes), value.to_ruby(scopes)]
      end
    end
  end
end
