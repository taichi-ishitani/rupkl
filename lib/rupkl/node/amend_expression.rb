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
        resolve_structure(context).evaluate(context)
      end

      def resolve_structure(context = nil)
        t =
          target
            .resolve_reference(context)
            .resolve_structure(context)
        t.respond_to?(:body) ||
          begin
            message = "cannot amend the target type #{t.class_name}"
            raise EvaluationError.new(message, position)
          end
        do_amend(t.copy(parent))
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, target.copy, bodies.each(&:copy), position)
      end

      private

      def do_amend(target)
        bodies
          .map { _1.copy(target).resolve_structure }
          .then { target.merge!(*_1) }
        target
      end
    end
  end
end
