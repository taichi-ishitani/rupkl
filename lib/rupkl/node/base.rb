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
      add_builtin_class Int
      add_builtin_class Float
      add_builtin_class String
      add_builtin_class Dynamic
      add_builtin_class Mapping
      add_builtin_class Listing
      add_builtin_class PklModule
    end
  end
end
