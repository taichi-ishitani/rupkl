# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:nl) do
        match('\n')
      end

      rule(:ws?) do
        match('[ \t\f\r\n;]').repeat.ignore
      end

      rule(:pure_ws?) do
        match('[ \t\f]').repeat.ignore
      end

      private

      def bracketed(atom, bra = '(', cket = ')')
        str(bra).ignore >> ws? >> atom >> ws? >> str(cket).ignore
      end
    end
  end
end
