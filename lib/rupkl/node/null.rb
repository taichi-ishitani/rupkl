# frozen_string_literal: true

module RuPkl
  module Node
    class Null < Any
      include ValueCommon

      uninstantiable_class

      def initialize(parent, position)
        super(parent, nil, position)
      end

      def to_string(_context = nil)
        'null'
      end

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end
    end
  end
end
