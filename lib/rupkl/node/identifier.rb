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

      def copy(parent = nil, position = @position)
        self.class.new(parent, id, position)
      end

      def ==(other)
        id ==
          if other.respond_to?(:id)
            other.id
          else
            other
          end
      end

      def to_sym
        id.to_sym
      end
    end
  end
end
