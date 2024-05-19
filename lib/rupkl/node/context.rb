# frozen_string_literal: true

module RuPkl
  module Node
    class Context
      def initialize(scopes, objects, local)
        @scopes = scopes
        @objects = objects
        @local = local
      end

      attr_reader :scopes
      attr_reader :objects
      attr_reader :local

      def push_scope(scope)
        Context.new([*scopes, scope], objects, nil)
      end

      def push_object(object)
        Context.new(scopes, [*objects, object], nil)
      end

      def push_local_context(local)
        Context.new(scopes, objects, local)
      end

      def pop
        Context.new(scopes&.[](..-2), objects&.[](..-2), local)
      end
    end
  end
end
