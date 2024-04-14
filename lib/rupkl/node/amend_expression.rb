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
        t.class.new(do_amend(scopes, t), position)
      end

      private

      def do_amend(scopes, target)
        bodies
          .map { _1.evaluate_lazily(scopes) }
          .then { target.body.merge!(*_1) }
      end
    end
  end
end
