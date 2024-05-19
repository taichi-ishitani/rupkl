# frozen_string_literal: true

module RuPkl
  module Node
    class MethodCall
      include NodeCommon
      include ReferenceResolver

      def initialize(parent, receiver, method_name, arguments, position)
        super(parent, receiver, method_name, *arguments, position)
        @receiver = receiver
        @method_name = method_name
        @arguments = arguments
      end

      attr_reader :receiver
      attr_reader :method_name
      attr_reader :arguments

      def evaluate_lazily(_context = nil)
        self
      end

      def evaluate(context = nil)
        pkl_method = resolve_reference(context, receiver, method_name)
        pkl_method.call(receiver, arguments, context || current_context, position)
      end

      def copy(parent = nil)
        copied_args = arguments&.map(&:copy)
        self.class.new(parent, receiver&.copy, method_name, copied_args, position)
      end

      private

      def get_member_node(scope, target)
        return unless scope.respond_to?(:pkl_methods)

        scope
          &.pkl_methods
          &.find { _1.name == target }
      end

      def unresolve_reference_error(target)
        m = "cannot find method '#{target.id}'"
        raise EvaluationError.new(m, position)
      end
    end
  end
end
