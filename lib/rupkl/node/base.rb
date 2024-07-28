# frozen_string_literal: true

module RuPkl
  module Node
    class Base < PklModule
      include Singleton

      def initialize
        super(nil, nil, nil)
      end

      attr_reader :pkl_classes

      class << self
        private

        def add_builtin_class(klass)
          instance.instance_eval do
            name = klass.class_name
            (@pkl_classes ||= {})[name] = klass
          end
        end
      end

      add_builtin_class Any
      add_builtin_class Boolean
      add_builtin_class Number
      add_builtin_class Int
      add_builtin_class Float
      add_builtin_class String
      add_builtin_class Dynamic
      add_builtin_class Mapping
      add_builtin_class Listing
      add_builtin_class PklModule

      define_builtin_property(:NaN) do
        Float.new(self, ::Float::NAN, position)
      end

      define_builtin_property(:Infinity) do
        Float.new(self, ::Float::INFINITY, position)
      end

      define_builtin_method(
        :List, elements: [Any, varparams: true]
      ) do |args, parent, position|
        List.new(parent, args[:elements], position)
      end

      define_builtin_method(
        :Set, elements: [Any, varparams: true]
      ) do |args, parent, position|
        Set.new(parent, args[:elements], position)
      end

      define_builtin_method(:Pair, first: Any, second: Any) do |args, parent, position|
        Pair.new(parent, args[:first], args[:second], position)
      end
    end
  end
end
