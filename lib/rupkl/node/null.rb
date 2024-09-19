# frozen_string_literal: true

module RuPkl
  module Node
    class Null < Any
      include ValueCommon
      include Operatable

      uninstantiable_class

      def initialize(parent, position)
        super(parent, nil, position)
      end

      def to_string(_context = nil)
        'null'
      end

      def null?
        true
      end
    end
  end
end
