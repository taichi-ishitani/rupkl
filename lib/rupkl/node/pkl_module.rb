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

      private

      def add_property(property)
        (@properties ||= []) << property
      end
    end
  end
end
