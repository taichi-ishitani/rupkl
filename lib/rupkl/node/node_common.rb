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

      def to_ruby(scopes)
        evaluate(scopes).to_ruby(scopes)
      end

      def to_string(scopes)
        evaluate(scopes).to_string(scopes)
      end

      def to_pkl_string(scopes)
        evaluate(scopes).to_pkl_string(scopes)
      end

      def copy
        self
      end

      private

      def add_child(child)
        (@children ||= []) << child
        child.instance_exec(self) { @parent = _1 }
      end
    end
  end
end
