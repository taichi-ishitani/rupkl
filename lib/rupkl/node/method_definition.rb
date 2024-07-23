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

      def varparam?
        false
      end
    end

    class VariadicMethodParam < MethodParam
      def check_type(values, context, position)
        values.each { |v| super(v, context, position) }
      end

      def varparam?
        true
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
          .tap { |result| overwrite_position(result, position) }
      end

      private

      def evaluate_arguments(arguments, context, position)
        check_arity(arguments, position)

        params&.map&.with_index do |param, i|
          arg =
            if param.varparam?
              Array(arguments&.[](i..))
            else
              arguments&.[](i)
            end
          evaluate_argument(param, arg, context)
        end
      end

      def check_arity(arguments, position)
        n_args = arguments&.size || 0
        n_params = n_params_range
        return if n_args in ^n_params

        m = "expected #{n_params} method arguments but got #{n_args}"
        raise EvaluationError.new(m, position)
      end

      def n_params_range
        n_params = params&.size || 0
        params&.last&.varparam? && (n_params - 1..) || n_params
      end

      def evaluate_argument(param, arg, context)
        value =
          if param.varparam?
            arg.map { _1.evaluate(context) }
          else
            arg.evaluate(context)
          end
        param.check_type(value, context, position)
        [param.name, value]
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

      def overwrite_position(result, position)
        result.instance_exec(position) { @position = _1 }
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

    class BuiltinVariadicMethodParam < VariadicMethodParam
      def initialize(name, klass)
        id = Identifier.new(nil, name, nil)
        type = BuiltinMethodTypeChecker.new(klass)
        super(nil, id, type, nil)
      end
    end

    class BuiltinMethodDefinition < MethodDefinition
      def initialize(name, **params, &body)
        id = Identifier.new(nil, name, nil)
        list = param_list(params)
        super(nil, id, list, nil, nil, nil)
        @body = body
      end

      private

      def param_list(params)
        params.map do |name, type|
          case type
          in [klass, { varparams: true }]
            BuiltinVariadicMethodParam.new(name, klass)
          else
            BuiltinMethodParams.new(name, type)
          end
        end
      end

      def execute_method(receiver, arguments)
        receiver.instance_exec(*arguments&.map(&:last), &body)
      end
    end
  end
end
