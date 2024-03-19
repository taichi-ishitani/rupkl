# frozen_string_literal: true

module RuPkl
  class Parser
    WS_PATTERN = '[ \t\f\r\n;]'

    define_parser do
      rule(:nl) do
        match('\n')
      end

      rule(:ws) do
        match(WS_PATTERN).repeat(1).ignore
      end

      rule(:ws?) do
        match(WS_PATTERN).repeat.ignore
      end

      rule(:pure_ws?) do
        match('[ \t\f]').repeat.ignore
      end

      private

      def bracketed(atom, bra = '(', cket = ')')
        bra_matcher, cket_matcher =
          [bra, cket]
            .map { _1.is_a?(String) && str(_1).ignore || _1 }
        bra_matcher >> ws? >> atom >> ws? >> cket_matcher
      end
    end
  end
end
