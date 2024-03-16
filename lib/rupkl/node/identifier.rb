# frozen_string_literal: true

module RuPkl
  module Node
    class Identifier
      def initialize(id, position)
        @id = id
        @position = position
      end

      attr_reader :id
      attr_reader :position

      def to_ruby(_scopes)
        id
      end
    end
  end
end
