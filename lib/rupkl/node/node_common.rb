# frozen_string_literal: true

module RuPkl
  module Node
    module NodeCommon
      def initialize(*children, position)
        @position = position
        children.each { _1 && add_child(_1) }
      end

      attr_reader :parent
      attr_reader :children
      attr_reader :position

      def to_ruby(...)
        evaluate(...).to_ruby(...)
      end

      def to_string(...)
        evaluate(...).to_string(...)
      end

      def to_pkl_string(...)
        evaluate(...).to_pkl_string(...)
      end

      def copy
        self
      end

      private

      def add_child(child)
        (@children ||= []) << child
        child.instance_exec(self) { @parent = _1 }
      end

      def push_scope(context, scope)
        c = context&.push_scope(scope) || Context.new([scope], nil)
        yield c if block_given?
      end

      def push_object(context, object)
        c = context&.push_object(object) || Context.new(nil, [object])
        yield c if block_given?
      end
    end
  end
end
