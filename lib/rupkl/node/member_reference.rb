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
        member_node =
          if receiver
            find_member([receiver.evaluate(scopes)])
          else
            find_member(scopes)
          end
        member_node.evaluate(scopes).value
      end

      def evaluate_lazily(_scopes)
        self
      end

      def to_string(scopes)
        evaluate(scopes).to_string(nil)
      end

      def to_pkl_string(scopes)
        evaluate(scopes).to_pkl_string(nil)
      end

      private

      def find_member(scopes)
        scopes.reverse_each do |scope|
          node = scope&.properties&.find { _1.name.id == member.id }
          return node if node
        end

        raise EvaluationError.new("cannot find property '#{member.id}'", position)
      end
    end
  end
end
