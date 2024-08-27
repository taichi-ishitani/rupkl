# frozen_string_literal: true

module RuPkl
  module Node
    class IfExpression
      include NodeCommon

      def condition
        @children[0]
      end

      def if_expression
        @children[1]
      end

      def else_expression
        @children[2]
      end
    end
  end
end
