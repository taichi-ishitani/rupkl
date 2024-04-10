# frozen_string_literal: true

module RuPkl
  module Node
    class DeclaredType
      include NodeCommon

      def initialize(type, position)
        super(*type, position)
        @type = type
      end

      attr_reader :type
    end
  end
end
