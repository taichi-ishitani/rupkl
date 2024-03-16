# frozen_string_literal: true

module RuPkl
  module Node
    class PklClassProperty
      def initialize(name, value, position)
        @name = name
        @value = value
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :position

      def evaluate(scopes)
        self.class.new(name, value.evaluate(scopes), position)
      end

      def to_ruby(scopes)
        [name.to_ruby(scopes), value.to_ruby(scopes)]
      end
    end
  end
end
