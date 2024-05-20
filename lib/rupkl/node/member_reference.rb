# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      include NodeCommon
      include ReferenceResolver

      def initialize(parent, receiver, member, position)
        super
        @receiver = receiver
        @member = member
      end

      attr_reader :receiver
      attr_reader :member

      def evaluate(context = nil)
        do_evaluate do
          resolve_member_reference(context, receiver, member).evaluate
        end
      end

      def resolve_reference(context = nil)
        do_evaluate do
          resolve_member_reference(context, receiver, member).resolve_reference
        end
      end

      def copy(parent = nil)
        self
          .class.new(parent, receiver&.copy, member&.copy, position)
          .tap { copy_scope_index(_1) }
      end

      private

      def do_evaluate
        @evaluating &&
          (raise EvaluationError.new('circular reference is detected', position))

        @evaluating = true
        result = yield
        @evaluating = false

        result
      end

      def unresolve_reference_error(target)
        EvaluationError.new("cannot find property '#{target.id}'", position)
      end

      def get_member_node(scope, target)
        return unless scope.respond_to?(:properties)

        scope
          .properties
          &.find { _1.name == target }
          &.value
      end
    end
  end
end
