# frozen_string_literal: true

module RuPkl
  module Node
    class This
      include NodeCommon

      def evaluate(scopes)
        evaluate_lazily(scopes)
      end

      def evaluate_lazily(scopes)
        scopes.last
      end
    end
  end
end
