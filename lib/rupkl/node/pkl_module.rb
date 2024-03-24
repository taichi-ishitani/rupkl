# frozen_string_literal: true

module RuPkl
  module Node
    class PklModule
      include StructCommon

      def initialize(items, position)
        @position = position
        items&.each do |item|
          case item
          when PklClassProperty then add_property(item)
          end
        end
      end

      attr_reader :properties
      attr_reader :position

      def evaluate(scopes)
        push_scope(scopes) do |s|
          evaluated_properties =
            properties&.map { _1.evaluate(s) }
          self.class.new(evaluated_properties, position)
        end
      end

      def to_ruby(scopes)
        push_scope(scopes) do |s|
          properties&.to_h { _1.to_ruby(s) } || {}
        end
      end

      private

      def add_property(property)
        (@properties ||= []) << property
      end
    end
  end
end
