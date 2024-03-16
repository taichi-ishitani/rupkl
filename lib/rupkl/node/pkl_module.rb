# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule
      def initialize(items, position)
        @position = position
        items&.each do |type, item|
          case type
          when :property then add_property(item)
          end
        end
      end

      attr_reader :properties
      attr_reader :position

      def evaluate(scopes)
        evaluated_properties =
          properties&.map { [:property, _1.evaluate(scopes)] }
        self.class.new(evaluated_properties, position)
      end

      def to_ruby(scopes)
        properties&.to_h { _1.to_ruby(scopes) } || {}
      end

      private

      def add_property(property)
        (@properties ||= []) << property
      end
    end
  end
end
