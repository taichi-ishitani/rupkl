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
        [*scopes, self].then do |s|
          self.class.new(evaluate_properties(s), position)
        end
      end

      def to_ruby(scopes)
        evaluate(scopes).then do |m|
          create_pkl_object(m.properties, nil, nil)
        end
      end

      private

      def add_property(property)
        (@properties ||= []) << property
      end

      def evaluate_properties(scopes)
        properties&.each_with_object([]) do |property, result|
          property
            .evaluate(scopes)
            .then { add_hash_member(result, _1, :name) }
        end
      end
    end
  end
end
