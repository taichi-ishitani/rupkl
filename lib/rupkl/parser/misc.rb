# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      private

      def nl
        match('[\n]')
      end
    end
  end
end
