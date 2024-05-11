# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      include NodeCommon

      def initialize(parent, receiver, member, position)
        super
        @receiver = receiver
        @member = member
      end

      attr_reader :receiver
      attr_reader :member

      def evaluate(context = nil)
        do_evaluate do
          resolve_reference(context).evaluate
        end
      end

      def evaluate_lazily(context = nil)
        do_evaluate do
          resolve_reference(context).evaluate_lazily
        end
      end

      def copy(parent = nil)
        self
          .class.new(parent, receiver&.copy, member&.copy, position)
          .tap do |node|
            @scope_index &&
              node.instance_exec(@scope_index) { @scope_index = _1 }
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

      def resolve_reference(context)
        scopes =
          if receiver
            [receiver.evaluate_lazily]
          else
            context ||= current_context
            [*context.scopes].insert(-2, context.objects&.last)
          end
        find_member(scopes)
      end

      def find_member(scopes)
        if @scope_index
          get_member_node(scopes[@scope_index])
        else
          search_member(scopes)
        end
      end

      def search_member(scopes)
        node, index = search_member_from_scopes(scopes)
        if node
          @scope_index = index
          return node
        end

        raise EvaluationError.new("cannot find property '#{member.id}'", position)
      end

      def search_member_from_scopes(scopes)
        scopes.reverse_each.with_index do |scope, i|
          node = get_member_node(scope)
          return [node, scopes.size - i - 1] if node
        end

        nil
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
