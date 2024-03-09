# frozen_string_literal: true

module RuPkl
  class Parser
    class Source < Parslet::Source
      def initialize(str, filename)
        super(str)
        @filename = filename
      end

      attr_reader :filename
    end

    class Parser < Parslet::Parser
      def parse(io, filename: nil, root: nil)
        source = Source.new(io, filename)
        root_parser(root).parse(source)
      rescue Parslet::ParseFailed => e
        raise_parse_error(e)
      end

      def root_parser(root)
        root && __send__(root) || __send__(:root)
      end

      private

      def raise_parse_error(error)
        cause = error.parse_failure_cause
        source = cause.source
        filename = source.filename
        line, column = source.line_and_column(cause.pos)
        message = compose_error_message(cause)
        raise ParseError.new(message, filename, line, column, cause)
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
        Node::Position.new(@filename, *node.line_and_column)
      end

      def parse_error(message, slice)
        line, column = slice.line_and_column
        raise ParseError.new(message, @filename, line, column, nil)
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

    def initialize(root = nil)
      @root = root
    end

    def parse(string, filename: nil)
      tree = parse_string(string, filename)
      transform_tree(tree, filename)
    end

    def inspect
      # :nocov:
      parser.root_parser(@root).inspect
      # :nocov:
    end

    private

    def parse_string(string, filename)
      parser.parse(string, filename: filename, root: @root)
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
