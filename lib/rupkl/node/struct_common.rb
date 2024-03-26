# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      private

      def push_scope(scopes)
        yield([*scopes, self])
      end

      def match_members?(lhs, rhs, match_order)
        if !match_order && [lhs, rhs].all?(Array)
          lhs.size == rhs.size &&
            lhs.all? { rhs.include?(_1) } && rhs.all? { lhs.include?(_1) }
        else
          lhs == rhs
        end
      end

      def evaluate_hash_members(members, scopes, accessor)
        members&.each_with_object([]) do |member, result|
          member.evaluate(scopes).then do |m|
            duplicate_member?(result, m, accessor) &&
              (raise EvaluationError.new('duplicate definition of member', m.position))
            result << m
          end
        end
      end

      def duplicate_member?(members, member, accessor)
        members
          .any? { _1.__send__(accessor) == member.__send__(accessor) }
      end

      def evaluate_array_members(members, scopes)
        members&.map { _1.evaluate(scopes) }
      end

      def to_ruby_hash_members(members, scopes, accessor)
        evaluate_hash_members(members, scopes, accessor)
          &.to_h { _1.to_ruby(scopes) } || {}
      end

      def to_ruby_array_members(members, scopes)
        evaluate_array_members(members, scopes)
          &.map { _1.to_ruby(scopes) } || []
      end
    end
  end
end
