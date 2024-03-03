# frozen_string_literal: true

module RuPkl
  class Parser
    #
    # Boolean literal
    #
    define_parser do
      rule(:boolean_literal) do
        kw_true.as(:true_value) | kw_false.as(:false_value)
      end
    end

    define_transform do
      rule(true_value: simple(:v)) do
        Node::Boolean.new(true, node_position(v))
      end

      rule(false_value: simple(:v)) do
        Node::Boolean.new(false, node_position(v))
      end
    end

    #
    # Integer literal
    #
    define_parser do
      rule(:bin_literal) do
        match('[+-]').maybe >>
          (str('0b') | str('0B')) >> match('[01]') >> match('[_01]').repeat
      end

      rule(:oct_literal) do
        match('[+-]').maybe >>
          (str('0o') | str('0O')) >> match('[0-7]') >> match('[_0-7]').repeat
      end

      rule(:dec_literal) do
        match('[+-]').maybe >>
          match('[\d]') >> match('[_\d]').repeat
      end

      rule(:hex_literal) do
        match('[+-]').maybe >>
          (str('0x') | str('0X')) >> match('[\h]') >> match('[_\h]').repeat
      end

      rule(:integer_literal) do
        (
          bin_literal | oct_literal | dec_literal | hex_literal
        ).as(:integer_literal)
      end
    end

    define_transform do
      rule(integer_literal: simple(:v)) do
        value = Integer(v.to_s.tr('_', '').sub(/\A(?!0[box])0+/i, ''))
        Node::Integer.new(value, node_position(v))
      end
    end
  end
end
