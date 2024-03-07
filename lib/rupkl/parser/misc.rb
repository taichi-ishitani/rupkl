# frozen_string_literal: true

module RuPkl
  class Parser
    KEYWORDS = [
      'abstract', 'amends', 'as', 'class', 'const', 'else', 'extends',
      'external', 'false', 'fixed', 'for', 'function', 'hidden', 'if',
      'import', 'import*', 'in', 'is', 'let', 'local', 'module', 'new',
      'nothing', 'null', 'open', 'out', 'outer', 'read', 'read*', 'read?',
      'super', 'this', 'throw', 'trace', 'true', 'typealias', 'unknown', 'when'
    ].freeze

    RESERVED_KEYWORDS = [
      'protected', 'override', 'record', 'delete', 'case', 'switch', 'vararg'
    ].freeze

    define_parser do
      [*KEYWORDS, *RESERVED_KEYWORDS].each do |kw|
        rule(:"kw_#{kw}") do
          str(kw) >> match('\\w').absent?
        end
      end

      private

      def nl
        match('[\n]')
      end
    end
  end
end
