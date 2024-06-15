# frozen_string_literal: true

module RuPkl
  module Node
    class MethodParam
      include NodeCommon

      def initialize(parent, name, type, position)
        super
        @name = name
        @type = type
      end

      attr_reader :name
      attr_reader :type

      def check_type(value, context, position)
        type&.check_type(value, context, position)
      end
    end

    class MethodDefinition
      include NodeCommon

      def initialize(parent, name, params, type, body, position)
        super(parent, name, *params, type, body, position)
        @name = name
        @params = params
        @type = type
        @body = body
      end

      attr_reader :name
      attr_reader :params
      attr_reader :type
      attr_reader :body

      def call(receiver, arguments, context, position)
        args = evaluate_arguments(arguments, context, position)
        execute_method(receiver, args)
      end

      private

      def evaluate_arguments(arguments, context, position)
        check_arity(arguments, position)

        arguments&.zip(params)&.map do |arg, param|
          evaluate_argument(arg, param, context)
        end
      end

      def evaluate_argument(arg, param, context)
        value = arg.evaluate(context)
        param.check_type(value, context, position)
        [param.name, value]
      end

      def check_arity(arguments, position)
        n_args = arguments&.size || 0
        n_params = params&.size || 0
        return if n_args == n_params

        m = "expected #{n_params} method arguments but got #{n_args}"
        raise EvaluationError.new(m, position)
      end

      def execute_method(receiver, arguments)
        context = create_call_context(receiver, arguments)
        execute_body(context)
      end

      def create_call_context(receiver, arguments)
        local_context = MethodCallContext.new(arguments)
        method_context = current_context
        if receiver
          Context.new([*method_context.scopes, local_context], [receiver])
        else
          method_context.push_scope(local_context)
        end
      end

      def execute_body(context)
        body.evaluate(context)
      end
    end

    class MethodCallContext
      include NodeCommon

      def initialize(arguments)
        @properties =
          arguments&.map do |(name, value)|
            ObjectProperty.new(nil, name, value, nil)
          end
        super(nil, *@properties, nil)
      end

      attr_reader :properties
    end
  end
end
