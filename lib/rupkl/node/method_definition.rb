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
        @body = body&.copy # reset `#parent` handle
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
        body
          .evaluate(context)
          .tap { type&.check_type(_1, context, position) }
      end
    end

    class MethodCallContext
      include NodeCommon
      include MemberFinder

      def initialize(arguments)
        @properties =
          arguments&.map do |(name, value)|
            ObjectProperty.new(nil, name, value, nil)
          end
        super(nil, *@properties, nil)
      end

      attr_reader :properties
    end

    class BuiltinMethodTypeChecker
      include TypeCommon

      def initialize(klass)
        super(nil, nil)
        @klass = klass
      end

      private

      def match_type?(klass, _context)
        klass <= @klass
      end
    end

    class BuiltinMethodParams < MethodParam
      def initialize(name, klass)
        id = Identifier.new(nil, name, nil)
        type = BuiltinMethodTypeChecker.new(klass)
        super(nil, id, type, nil)
      end
    end

    class BuiltinMethodDefinition < MethodDefinition
      def initialize(name, **params, &body)
        param_list = params.map { |n, t| BuiltinMethodParams.new(n, t) }
        id = Identifier.new(nil, name, nil)
        super(nil, id, param_list, nil, nil, nil)
        @body = body
      end

      private

      def execute_method(receiver, arguments)
        receiver.instance_exec(*arguments&.map(&:last), &body)
      end
    end
  end
end
