# frozen_string_literal: true

module RuPkl
  module Node
    module ReferenceResolver
      private

      def resolve_member_reference(context, receiver, target)
        scopes =
          if receiver
            [evaluate_receiver(receiver)]
          else
            exec_on(context) do |c|
              [c&.objects&.last, Base.instance, *c&.scopes]
            end
          end
        find_member(scopes, target)
      end

      def evaluate_receiver(receiver)
        return unless receiver

        if receiver.structure?
          receiver.resolve_reference.resolve_structure
        else
          receiver.evaluate
        end
      end

      def find_member(scopes, target)
        if scope_index.index
          get_member_node(scopes[scope_index.index], target)
        else
          search_member(scopes, target)
        end
      end

      def search_member(scopes, target)
        node, index = search_member_from_scopes(scopes, target)
        if node
          scope_index.index = index
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

      ScopeIndex = Struct.new(:index)

      def scope_index
        @scope_index ||= ScopeIndex.new
      end

      def copy_scope_index(target)
        target.instance_exec(scope_index) { @scope_index = _1 }
      end
    end
  end
end
