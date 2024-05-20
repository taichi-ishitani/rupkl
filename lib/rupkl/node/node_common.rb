# frozen_string_literal: true

module RuPkl
  module Node
    module NodeCommon
      def initialize(parent, *children, position)
        @position = position
        parent&.add_child(self)
        children.each { add_child(_1) }
      end

      attr_reader :parent
      attr_reader :children
      attr_reader :position

      def resolve_reference(_context = nil)
        self
      end

      def resolve_structure(_context = nil)
        self
      end

      def to_ruby(context = nil)
        evaluate(context).to_ruby(context)
      end

      def to_string(context = nil)
        evaluate(context).to_string(context)
      end

      def to_pkl_string(context = nil)
        evaluate(context).to_pkl_string(context)
      end

      def add_child(child)
        return unless child

        child.parent ||
          child.instance_exec(self) { @parent = _1 }

        @children&.any? { _1.equal?(child) } ||
          (@children ||= []) << child
      end

      def copy(parent = nil)
        copied_children = children&.map(&:copy)
        self.class.new(parent, *copied_children, position)
      end

      def current_context
        parent&.current_context
      end

      private

      INVALID_STRING = String.new('?').freeze

      def invalid_string
        INVALID_STRING
      end

      def invalid_string?(string)
        string.equal?(INVALID_STRING)
      end
    end
  end
end
