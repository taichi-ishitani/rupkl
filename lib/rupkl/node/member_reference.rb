# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      include NodeCommon

      def initialize(receiver, member, position)
        super
        @receiver = receiver
        @member = member
      end

      attr_reader :receiver
      attr_reader :member

      def evaluate(scopes)
        do_evaluate do
          resolve_reference(scopes).evaluate(scopes)
        end
      end

      def evaluate_lazily(scopes)
        do_evaluate do
          resolve_reference(scopes).evaluate_lazily(scopes)
        end
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

      def resolve_reference(scopes)
        if receiver
          find_member([receiver.evaluate_lazily(scopes)])
        else
          find_member(scopes)
        end
      end

      def find_member(scopes)
        if @scope_index
          get_member_node(scopes[@scope_index])
        else
          search_member(scopes)
        end
      end

      def search_member(scopes)
        scopes.reverse_each.with_index do |scope, i|
          node = get_member_node(scope)
          if node
            @scope_index = scopes.size - i - 1
            return node
          end
        end

        raise EvaluationError.new("cannot find property '#{member.id}'", position)
      end

      def get_member_node(scope)
        return unless scope.respond_to?(:properties)

        scope
          &.properties
          &.find { _1.name == member }
          &.value
      end
    end
  end
end
