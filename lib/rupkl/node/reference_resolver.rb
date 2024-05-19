# frozen_string_literal: true

module RuPkl
  module Node
    module ReferenceResolver
      private

      def resolve_reference(context, receiver, target)
        scopes =
          if receiver
            [receiver.evaluate_lazily]
          else
            context ||= current_context
            [
              *context.scopes[..-2], context.objects&.last,
              context.scopes.last, context.local
            ]
          end
        find_member(scopes, target)
      end

      def find_member(scopes, target)
        if @scope_index
          get_member_node(scopes[@scope_index], target)
        else
          search_member(scopes, target)
        end
      end

      def search_member(scopes, target)
        node, index = search_member_from_scopes(scopes, target)
        if node
          @scope_index = index
          return node
        end

        raise unresolve_reference_error(target)
      end

      def search_member_from_scopes(scopes, target)
        scopes.reverse_each.with_index do |scope, i|
          node = get_member_node(scope, target)
          return [node, scopes.size - i - 1] if node
        end

        nil
      end
    end
  end
end
