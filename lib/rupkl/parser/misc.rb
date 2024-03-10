# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:ws?) do
        match('[ \t\f\r\n;]').repeat.ignore
      end

      rule(:nl) do
        match('\n')
      end
    end
  end
end
