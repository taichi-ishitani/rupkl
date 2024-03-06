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
          str('0b') >> match('[01]') >> match('[_01]').repeat
      end

      rule(:oct_literal) do
        match('[+-]').maybe >>
          str('0o') >> match('[0-7]') >> match('[_0-7]').repeat
      end

      rule(:dec_literal) do
        match('[+-]').maybe >>
          match('[\d]') >> match('[_\d]').repeat
      end

      rule(:hex_literal) do
        match('[+-]').maybe >>
          str('0x') >> match('[\h]') >> match('[_\h]').repeat
      end

      rule(:integer_literal) do
        (
          bin_literal | oct_literal | dec_literal | hex_literal
        ).as(:integer_literal)
      end
    end

    define_transform do
      rule(integer_literal: simple(:v)) do
        value = Integer(v.to_s.tr('_', '').sub(/\A(?!0[box])0+/, ''))
        Node::Integer.new(value, node_position(v))
      end
    end

    #
    # String literal
    #
    ESCAPED_CHARS =
      {
        't' => "\t", 'n' => "\n", 'r' => "\r",
        '"' => '"', '\\' => '\\'
      }.freeze

    define_parser do
      rule(:sl_string_literal) do
        str('"').as(:sl_bq) >>
          sl_portions('').as(:sl_portions).maybe >> sl_eq('').as(:sl_eq)
      end

      rule(:sl_string_literal_custom_delimiters) do
        (str('#').repeat(1) >> str('"')).capture(:bq).as(:sl_bq) >>
          dynamic do |_, c|
            pounds = c.captures[:bq].to_s[0..-2]
            sl_portions(pounds).as(:sl_portions).maybe >> sl_eq(pounds).as(:sl_eq)
          end
      end

      rule(:string_literal) do
        sl_string_literal_custom_delimiters | sl_string_literal
      end

      private

      def escaped_char(pounds)
        str("\\#{pounds}") >>
          match("[#{Regexp.escape(ESCAPED_CHARS.keys.join)}]")
      end

      def unicode_char(pounds)
        str("\\#{pounds}u") >> str('{') >> match('[\h]').repeat(1) >> str('}')
      end

      def sl_char(pounds)
        (str("\n") | sl_eq(pounds)).absent? >> any
      end

      def sl_string(pounds)
        (escaped_char(pounds) | unicode_char(pounds) | sl_char(pounds)).repeat(1)
      end

      def sl_portions(pounds)
        sl_string(pounds).as(:sl_string).repeat(1)
      end

      def sl_eq(pounds)
        str("\"#{pounds}")
      end
    end

    define_transform do
      rule(sl_bq: simple(:bq), sl_eq: simple(:eq)) do
        Node::String.new(nil, nil, node_position(bq))
      end

      rule(sl_bq: simple(:bq), sl_portions: sequence(:portions), sl_eq: simple(:eq)) do
        unescaped_portions = unescape_string_portions(portions, bq.to_s[0..-2])
        Node::String.new(nil, unescaped_portions, node_position(bq))
      end

      rule(sl_string: simple(:s)) do
        s.to_s
      end

      private

      def unescape_string_portions(portions, pounds)
        portions.map { unescape_string(_1, pounds) }
      end

      def unescape_string(string, pounds)
        string
          .then { unescape_char(_1, pounds) }
          .then { unescape_unicode(_1, pounds) }
      end

      def unescape_char(string, pounds)
        re = /\\#{pounds}([#{Regexp.escape(ESCAPED_CHARS.keys.join)}])/
        string.gsub(re) { ESCAPED_CHARS[Regexp.last_match(1)] }
      end

      def unescape_unicode(string, pounds)
        re = /\\#{pounds}u\{([\h]+)\}/
        string.gsub(re) { Regexp.last_match(1).to_i(16).chr(Encoding::UTF_8) }
      end
    end
  end
end
