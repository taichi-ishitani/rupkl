# frozen_string_literal: true

module RuPkl
  module Node
    class This
      include NodeCommon

      def evaluate(context)
        evaluate_lazily(context)
      end

      def evaluate_lazily(context)
        context.objects.last
      end
    end
  end
end
