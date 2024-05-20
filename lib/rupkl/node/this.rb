# frozen_string_literal: true

module RuPkl
  module Node
    class This
      include NodeCommon

      def evaluate(context = nil)
        resolve_reference(context)
      end

      def resolve_reference(context = nil)
        (context || current_context).objects.last
      end
    end
  end
end
