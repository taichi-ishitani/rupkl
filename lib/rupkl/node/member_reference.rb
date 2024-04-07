# frozen_string_literal: true

module RuPkl
  module Node
    class MemberReference
      def initialize(receiver, member, position)
        @receiver = receiver
        @member = member
        @position = position
      end

      attr_reader :receiver
      attr_reader :member
      attr_reader :position

      def evaluate(scopes)
        resolve_reference(scopes).evaluate(scopes).value
      end

      def evaluate_lazily(scopes)
        resolve_reference(scopes).evaluate_lazily(scopes).value
      end

      def to_string(scopes)
        evaluate(scopes).to_string(nil)
      end

      def to_pkl_string(scopes)
        evaluate(scopes).to_pkl_string(nil)
      end

      private

      def resolve_reference(scopes)
        if receiver
          find_member([receiver.evaluate(scopes)])
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
        scope&.properties&.find { _1.name == member }
      end
    end
  end
end
