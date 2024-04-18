# frozen_string_literal: true

module RuPkl
  module Node
    class AmendExpression
      include NodeCommon

      def initialize(target, bodies, position)
        super(target, *bodies, position)
        @target = target
        @bodies = bodies
      end

      attr_reader :target
      attr_reader :bodies

      def evaluate(scopes)
        evaluate_lazily(scopes).evaluate(scopes)
      end

      def evaluate_lazily(scopes)
        t = target.evaluate_lazily(scopes)
        t.respond_to?(:body) ||
          begin
            message = "cannot amend the target type #{t.class.basename}"
            raise EvaluationError.new(message, position)
          end
        do_amend(scopes, t.copy)
      end

      def copy
        self.class.new(target.copy, bodies.map(&:copy), position)
      end

      private

      def do_amend(scopes, target)
        bodies.each { _1.evaluate_lazily(scopes) }
        target.merge!(*bodies)
        target
      end
    end
  end
end
