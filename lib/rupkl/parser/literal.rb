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
      rule(:ss_literal) do
        ss_bq(custom: false).as(:ss_bq) >>
          ss_portions('').as(:ss_portions).maybe >> ss_eq('').as(:ss_eq)
      end

      rule(:ss_literal_custom_delimiters) do
        ss_bq(custom: true).capture(:bq).as(:ss_bq) >>
          dynamic do |_, c|
            pounds = c.captures[:bq].to_s[0..-2]
            ss_portions(pounds).as(:ss_portions).maybe >> ss_eq(pounds).as(:ss_eq)
          end
      end

      rule(:string_literal) do
        ss_literal_custom_delimiters | ss_literal
      end

      private

      def escaped_char(pounds)
        str("\\#{pounds}") >>
          match("[#{Regexp.escape(ESCAPED_CHARS.keys.join)}]")
      end

      def unicode_char(pounds)
        str("\\#{pounds}u") >> str('{') >> match('[\h]').repeat(1) >> str('}')
      end

      def ss_char(pounds)
        (str("\n") | ss_eq(pounds)).absent? >> any
      end

      def ss_string(pounds)
        (escaped_char(pounds) | unicode_char(pounds) | ss_char(pounds)).repeat(1)
      end

      def ss_portions(pounds)
        ss_string(pounds).as(:ss_string).repeat(1)
      end

      def ss_bq(custom:)
        if custom
          str('#').repeat(1) >> str('"')
        else
          str('"')
        end
      end

      def ss_eq(pounds)
        str("\"#{pounds}")
      end
    end

    define_transform do
      rule(ss_bq: simple(:bq), ss_eq: simple(:eq)) do
        Node::String.new(nil, nil, node_position(bq))
      end

      rule(ss_bq: simple(:bq), ss_portions: subtree(:portions), ss_eq: simple(:eq)) do
        Node::String.new(nil, process_ss_portions(portions, bq), node_position(bq))
      end

      private

      def process_ss_portions(portions, ss_bq)
        pounds = ss_bq.to_s[0..-2]
        portions.map { process_sring_portion(_1, pounds) }
      end

      def process_sring_portion(portion, pounds)
        type, string = portion.to_a.first
        case type
        when :ss_string then unescape_string(string, pounds)
        end
      end

      def unescape_string(string, pounds)
        string
          .to_s
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
