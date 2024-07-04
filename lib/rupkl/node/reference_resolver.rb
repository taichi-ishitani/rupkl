# frozen_string_literal: true

module RuPkl
  module Node
    module ReferenceResolver
      private

      def resolve_member_reference(context, target, receiver, nullable)
        scopes, raise_error, ifnone =
          if receiver
            evaluate_receiver(receiver, context)&.then do |r|
              [[r], raise_error?(r, nullable), ifnone_value(r)]
            end
          else
            exec_on(context) do |c|
              [[c&.objects&.last, Base.instance, *c&.scopes], true]
            end
          end
        find_member(scopes, target, raise_error, ifnone)
      end

      def raise_error?(receiver, nullable)
        !(nullable && receiver&.null?)
      end

      def evaluate_receiver(receiver, context)
        return unless receiver

        if receiver.structure?
          receiver
            .resolve_reference(context)
            .resolve_structure(context)
        else
          receiver.evaluate(context)
        end
      end

      def find_member(scopes, target, raise_error, ifnone)
        if scope_index.index
          get_member_node(scopes[scope_index.index], target)
        else
          search_member(scopes, target, raise_error, ifnone)
        end
      end

      def search_member(scopes, target, raise_error, ifnone)
        node, index = search_member_from_scopes(scopes, target)
        if node
          scope_index.index = index
          return node
        end

        raise_error &&
          (raise unresolve_reference_error(target))

        ifnone
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
