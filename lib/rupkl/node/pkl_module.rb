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
          self.class.new(evaluate_properties(s), position)
        end
      end

      def to_ruby(scopes)
        push_scope(scopes) do |s|
          to_ruby_hash_members(properties, s, :name)
        end
      end

      private

      def add_property(property)
        (@properties ||= []) << property
      end

      def evaluate_properties(scopes)
        evaluate_hash_members(properties, scopes, :name)
      end
    end
  end
end
