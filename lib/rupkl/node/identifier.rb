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
        other.instance_of?(self.class) && id == other.id
      end
    end
  end
end
