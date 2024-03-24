# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      private

      def push_scope(scopes)
        yield([*scopes, self])
      end
    end
  end
end
