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
    end
  end
end
