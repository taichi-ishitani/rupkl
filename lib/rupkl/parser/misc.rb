# frozen_string_literal: true

module RuPkl
  class Parser
    WS_PATTERN = '[ \t\f\r\n;]'

    define_parser do
      rule(:line_comment) do
        str('//') >> match('[^\n]').repeat >> (nl | eof)
      end

      rule(:block_comment) do
        str('/*') >> (block_comment | (str('*/').absent? >> any)).repeat >> str('*/')
      end

      rule(:comment) do
        line_comment | block_comment
      end

      rule(:nl) do
        match('\n')
      end

      rule(:eof) do
        any.absent?
      end

      rule(:ws) do
        (match(WS_PATTERN) | comment).repeat(1).ignore
      end

      rule(:ws?) do
        (match(WS_PATTERN) | comment).repeat.ignore
      end

      rule(:pure_ws?) do
        (match('[ \t\f]') | comment).repeat.ignore
      end

      private

      def bracketed(atom, bra = '(', cket = ')')
        bra_matcher, cket_matcher =
          [bra, cket]
            .map { _1.is_a?(String) && str(_1).ignore || _1 }
        bra_matcher >> ws? >> atom >> ws? >> cket_matcher
      end

      def list(atom, delimiter = ',')
        atom >> (ws? >> str(delimiter).ignore >> ws? >> atom).repeat
      end
    end
  end
end
