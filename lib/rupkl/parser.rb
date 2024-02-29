# frozen_string_literal: true

module RuPkl
  class Parser
    class Parser < Parslet::Parser
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
          super
        end
      end

      def respond_to_missing?(method, include_private)
        super || @__transform.respond_to?(method, include_private)
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
      transform.apply(parser.parse(string), filename: filename)
    end

    private

    def parser
      @parser ||= Parser.new
      @root && @parser.__send__(@root) || @parser
    end

    def transform
      @transform ||= Transform.new
    end
  end
end
