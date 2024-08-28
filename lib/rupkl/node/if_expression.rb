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

      def evaluate(context = nil)
        resolve_structure(context).evaluate(context)
      end

      def resolve_structure(context = nil)
        @result ||=
          if evaluate_condition(context)
            if_expression
          else
            else_expression
          end
        @result.resolve_structure(context)
      end

      private

      def evaluate_condition(context)
        evaluated = condition.evaluate(context)
        return evaluated.value if evaluated.is_a?(Boolean)

        message = "expected type 'Boolean', but got type '#{evaluated.class.basename}'"
        raise EvaluationError.new(message, position)
      end
    end
  end
end
