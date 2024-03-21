# frozen_string_literal: true

module RuPkl
  module Node
    class Float
      include ValueCommon

      def evaluate(_scopes)
        self
      end
    end
  end
end
