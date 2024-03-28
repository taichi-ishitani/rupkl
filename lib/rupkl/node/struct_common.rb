# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      private

      def add_hash_member(members, member, accessor)
        duplicate_member?(members, member, accessor) &&
          begin
            message = 'duplicate definition of member'
            raise EvaluationError.new(message, member.position)
          end
        members << member
      end

      def duplicate_member?(members, member, accessor)
        members
          .any? { _1.__send__(accessor) == member.__send__(accessor) }
      end

      def add_array_member(members, member)
        members << member
      end

      def match_members?(lhs, rhs, match_order)
        if !match_order && [lhs, rhs].all?(Array)
          lhs.size == rhs.size &&
            lhs.all? { rhs.include?(_1) } && rhs.all? { lhs.include?(_1) }
        else
          lhs == rhs
        end
      end

      def merge_hash_members(lhs, rhs, accessor)
        return nil unless lhs || rhs
        return rhs unless lhs

        rhs&.each do |r|
          if (index = find_index(lhs, r, accessor))
            lhs[index] = r
          else
            lhs << r
          end
        end

        lhs
      end

      def find_index(lhs, rhs, accessor)
        lhs.find_index { _1.__send__(accessor) == rhs.__send__(accessor) }
      end

      def merge_array_members(lhs, rhs)
        return nil unless lhs || rhs
        return rhs unless lhs
        return lhs unless rhs

        lhs.concat(rhs)
      end

      def to_ruby_hash_members(members, scopes)
        members
          &.to_h { _1.to_ruby(scopes) } || {}
      end

      def to_ruby_array_members(members, scopes)
        members
          &.map { _1.to_ruby(scopes) } || []
      end
    end
  end
end
