# frozen_string_literal: true

module RuPkl
  module Node
    class Identifier
      include NodeCommon

      def initialize(id, position)
        super(position)
        @id = id
      end

      attr_reader :id

      def ==(other)
        other.instance_of?(self.class) && id == other.id
      end
    end
  end
end
