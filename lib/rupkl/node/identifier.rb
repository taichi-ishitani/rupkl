# frozen_string_literal: true

module RuPkl
  module Node
    class Identifier
      include NodeCommon

      def initialize(parent, id, position)
        super(parent, position)
        @id = id
      end

      attr_reader :id

      def copy(parent = nil)
        self.class.new(parent, id, position)
      end

      def ==(other)
        case other
        when self.class then id == other.id
        when Symbol then id == other
        else false
        end
      end
    end
  end
end
