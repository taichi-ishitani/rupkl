# frozen_string_literal: true

module RuPkl
  module Node
    class This
      include NodeCommon

      def evaluate(context = nil)
        evaluate_lazily(context)
      end

      def evaluate_lazily(context = nil)
        context ||= current_context
        context.objects.last
      end
    end
  end
end
