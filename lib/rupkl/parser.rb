# frozen_string_literal: true

module RuPkl
  class Parser
    Position = Struct.new(:filename, :line, :column)

    class Parser < Parslet::Parser
      def parse(io, filename: nil, root: nil)
        root_parser(root).parse(io)
      rescue Parslet::ParseFailed => e
        raise_parse_error(e, filename)
      end

      def root_parser(root)
        root && __send__(root) || __send__(:root)
      end

      private

      def raise_parse_error(error, filename)
        cause = error.parse_failure_cause
        pos = create_error_pos(cause, filename)
        message = compose_error_message(cause)
        raise ParseError.new(message, pos, cause)
      end

      def create_error_pos(cause, filename)
        Position.new(filename, *cause.source.line_and_column(cause.pos))
      end

      def compose_error_message(cause)
        Array(cause.message)
          .map { |m| m.respond_to?(:to_slice) ? m.str.inspect : m.to_s }
          .join
      end
    end

    class Context < Parslet::Context
      def initialize(bindings, transform)
        super(bindings)
        @__transform = transform
      end

      def method_missing(method, ...)
        if @__transform.respond_to?(method, true)
          __define_delegator__(method)
          __send__(method, ...)
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def respond_to_missing?(method, include_private)
        # :nocov:
        super || @__transform.respond_to?(method, include_private)
        # :nocov:
      end

      private

      def __define_delegator__(method)
        self.class.class_eval(<<~M, __FILE__, __LINE__ + 1)
          # def foo(...)
          #   @__transform.__send__(:foo, ...)
          # end
          def #{method}(...)
            @__transform.__send__(:#{method}, ...)
          end
        M
      end
    end

    class Transform < Parslet::Transform
      def apply(obj, context = nil, filename: nil)
        @filename = filename if filename
        super(obj, context)
      end

      def call_on_match(bindings, block)
        return unless block

        context = Context.new(bindings, self)
        context.instance_exec(&block)
      end

      private

      def node_position(node)
        Position.new(@filename, *node.line_and_column)
      end

      def sof_position
        Position.new(@filename, 1, 1)
      end

      def parse_error(message, position)
        raise ParseError.new(message, position, nil)
      end
    end

    class << self
      private

      def define_parser(&body)
        Parser.class_eval(&body)
      end

      def define_transform(&body)
        Transform.class_eval(&body)
      end
    end

    def parse(string, filename: nil, root: nil)
      tree = parse_string(string, filename, root)
      transform_tree(tree, filename)
    end

    private

    def parse_string(string, filename, root)
      parser.parse(string, filename: filename, root: root)
    end

    def parser
      @parser ||= Parser.new
    end

    def transform_tree(tree, filename)
      transform.apply(tree, filename: filename)
    end

    def transform
      @transform ||= Transform.new
    end
  end
end
