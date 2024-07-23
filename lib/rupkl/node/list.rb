# frozen_string_literal: true

module RuPkl
  module Node
    class List < Collection
      uninstantiable_class

      def initialize(parent, elements, position)
        super(parent, *elements, position)
      end

      alias_method :elements, :children
    end
  end
end
