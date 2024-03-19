# frozen_string_literal: true

module RuPkl
  module Node
    class PklObjectProperty
      def initialize(name, value, objects, position)
        @name = name
        @value = value
        @objects = objects
      end

      attr_reader :name
      attr_reader :value
      attr_reader :objects
      attr_reader :position
    end

    class PklObjectEntry
      def initialize(key, value, objects, position)
        @key = key
        @value = value
        @objects = objects
      end

      attr_reader :key
      attr_reader :value
      attr_reader :objects
      attr_reader :position
    end

    class PklObject
      def initialize(members, position)
        @position = position
        members&.each do |member|
          case member
          when PklObjectProperty then add_property(member)
          when PklObjectEntry then add_entry(member)
          else add_element(member)
          end
        end
      end

      attr_reader :properties
      attr_reader :elements
      attr_reader :entries
      attr_reader :position

      private

      def add_property(property)
        (@properties ||= []) << property
      end

      def add_entry(entry)
        (@entries ||= []) << entry
      end

      def add_element(element)
        (@elements ||= []) << element
      end
    end
  end
end
