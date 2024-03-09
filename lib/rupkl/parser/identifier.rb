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

      rule(:regular_identifier) do
        (str('_') | str('$') | match('\p{XID_Start}')) >> match('\p{XID_Continue}').repeat
      end

      rule(:quoted_identifier) do
        str('`') >> (str('`').absent? >> any).repeat(1) >> str('`')
      end

      rule(:id) do
        regular_identifier.as(:regular_id) | quoted_identifier.as(:quoted_id)
      end
    end

    define_transform do
      rule(regular_id: simple(:id)) do
        keyword?(id) &&
          (parse_error "keyword '#{id}' is not allowed for identifier", id)
        Node::Identifier.new(id.to_s, node_position(id))
      end

      rule(quoted_id: simple(:id)) do
        Node::Identifier.new(id.to_s[1..-2], node_position(id))
      end

      private

      def keyword?(id)
        KEYWORDS.any?(id) || RESERVED_KEYWORDS.any?(id)
      end
    end
  end
end
