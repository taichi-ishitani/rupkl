# frozen_string_literal: true

module RuPkl
  module Node
    class Context
      def initialize(scopes, objects)
        @scopes = scopes
        @objects = objects
      end

      attr_reader :scopes
      attr_reader :objects

      def push_scope(scope)
        Context.new([*scopes, scope], objects)
      end

      def push_object(object)
        Context.new(scopes, [*objects, object])
      end

      def pop
        Context.new(scopes&.[](..-2), objects&.[](..-2))
      end
    end
  end
end
