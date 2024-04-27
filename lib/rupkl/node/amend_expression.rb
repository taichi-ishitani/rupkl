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

      def evaluate(context)
        evaluate_lazily(context).evaluate(context)
      end

      def evaluate_lazily(context)
        t = target.evaluate_lazily(context)
        t.respond_to?(:body) ||
          begin
            message = "cannot amend the target type #{t.class.basename}"
            raise EvaluationError.new(message, position)
          end
        do_amend(t.copy, context)
      end

      def copy
        self.class.new(target.copy, bodies.map(&:copy), position)
      end

      private

      def do_amend(target, context)
        push_object(context, target) do |c|
          bodies.each { |b| b.evaluate_lazily(c) }
          target.merge!(*bodies)
        end
        target
      end
    end
  end
end
