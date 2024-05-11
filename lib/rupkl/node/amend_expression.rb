# frozen_string_literal: true

module RuPkl
  module Node
    class AmendExpression
      include NodeCommon

      def initialize(parent, target, bodies, position)
        super(parent, target, *bodies, position)
        @target = target
        @bodies = bodies
      end

      attr_reader :target
      attr_reader :bodies

      def evaluate(context = nil)
        evaluate_lazily(context).evaluate(context)
      end

      def evaluate_lazily(context = nil)
        t = target.evaluate_lazily(context)
        t.respond_to?(:body) ||
          begin
            message = "cannot amend the target type #{t.class.basename}"
            raise EvaluationError.new(message, position)
          end
        do_amend(t.copy(parent))
      end

      def copy(parent = nil)
        self.class.new(parent, target.copy, bodies.each(&:copy), position)
      end

      private

      def do_amend(target)
        bodies
          .map { _1.copy(target).evaluate_lazily }
          .then { target.merge!(*_1) }
        target
      end
    end
  end
end
