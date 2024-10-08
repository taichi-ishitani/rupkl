# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      include NodeCommon
      include ReferenceResolver

      def initialize(parent, receiver, member, nullable, position)
        super(parent, receiver, member, position)
        @receiver = receiver
        @member = member
        @nullable = nullable
      end

      attr_reader :receiver
      attr_reader :member

      def nullable?
        @nullable
      end

      def evaluate(context = nil)
        do_evaluate do
          result = resolve_member_reference(context, member, receiver, nullable?)
          result.evaluate
        end
      end

      def resolve_reference(context = nil)
        do_evaluate do
          result = resolve_member_reference(context, member, receiver, nullable?)
          result.resolve_reference
        end
      end

      def copy(parent = nil, position = @position)
        self
          .class.new(parent, receiver&.copy, member&.copy, nullable?, position)
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

      def ifnone_value(receiver)
        receiver
      end

      def get_member_node(scope, target)
        return unless scope.respond_to?(:property)

        scope.property(target)
      end

      def unresolve_reference_error(target)
        EvaluationError.new("cannot find property '#{target.id}'", position)
      end
    end
  end
end
