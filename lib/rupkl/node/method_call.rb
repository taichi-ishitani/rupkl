# frozen_string_literal: true

module RuPkl
  module Node
    class MethodCall
      include NodeCommon
      include ReferenceResolver

      def initialize(parent, receiver, method_name, arguments, nullable, position)
        super(parent, receiver, method_name, *arguments, position)
        @receiver = receiver
        @method_name = method_name
        @arguments = arguments
        @nullable = nullable
      end

      attr_reader :receiver
      attr_reader :method_name
      attr_reader :arguments

      def nullable?
        @nullable
      end

      def evaluate(context = nil)
        exec_on(context) do |c|
          r = evaluate_receiver(receiver, c)
          m = resolve_member_reference(c, method_name, r, nullable?)
          m && execute_method(m, r, c) || r
        end
      end

      def copy(parent = nil)
        copied_args = arguments&.map(&:copy)
        self.class
          .new(parent, receiver&.copy, method_name, copied_args, nullable?, position)
          .tap { copy_scope_index(_1) }
      end

      private

      def ifnone_value(_)
        nil
      end

      def get_member_node(scope, target)
        return unless scope.respond_to?(:pkl_method)

        scope.pkl_method(target)
      end

      def unresolve_reference_error(target)
        m = "cannot find method '#{target.id}'"
        raise EvaluationError.new(m, position)
      end

      def execute_method(pkl_method, receiver, context)
        pkl_method
          .call(receiver, arguments, context, position)
          .tap { parent&.add_child(_1) }
      end
    end
  end
end
