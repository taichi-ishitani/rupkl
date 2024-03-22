# frozen_string_literal: true

module RuPkl
  module Node
    class Number
      include ValueCommon

      def evaluate(_scopes)
        self
      end
    end

    class Integer < Number
    end

    class Float < Number
    end
  end
end
