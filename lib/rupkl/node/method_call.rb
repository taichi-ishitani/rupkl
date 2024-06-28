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

      def evaluate(context = nil)
        receiver_node = evaluate_receiver(receiver)
        pkl_method = resolve_member_reference(context, receiver_node, method_name)
        exec_on(context) do |c|
          pkl_method.call(receiver_node, arguments, c, position)
        end
      end

      def copy(parent = nil)
        copied_args = arguments&.map(&:copy)
        self
          .class.new(parent, receiver&.copy, method_name, copied_args, position)
          .tap { copy_scope_index(_1) }
      end

      private

      def get_member_node(scope, target)
        return unless scope.respond_to?(:pkl_method)

        scope.pkl_method(target)
      end

      def unresolve_reference_error(target)
        m = "cannot find method '#{target.id}'"
        raise EvaluationError.new(m, position)
      end
    end
  end
end
