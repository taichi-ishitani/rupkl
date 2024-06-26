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
        Node::Boolean.new(nil, true, node_position(v))
      end

      rule(false_value: simple(:v)) do
        Node::Boolean.new(nil, false, node_position(v))
      end
    end

    #
    # Int literal
    #
    define_parser do
      rule(:bin_literal) do
        str('0b') >> match('[01]') >> match('[_01]').repeat
      end

      rule(:oct_literal) do
        str('0o') >> match('[0-7]') >> match('[_0-7]').repeat
      end

      rule(:dec_literal) do
        match('[\d]') >> match('[_\d]').repeat
      end

      rule(:hex_literal) do
        str('0x') >> match('[\h]') >> match('[_\h]').repeat
      end

      rule(:int_literal) do
        (
          bin_literal | oct_literal | hex_literal | dec_literal
        ).as(:int_literal)
      end
    end

    define_transform do
      rule(int_literal: simple(:v)) do
        base = { 'b' => 2, 'o' => 8, 'x' => 16 }.fetch(v.to_s[1], 10)
        value = v.to_s.tr('_', '').to_i(base)
        Node::Int.new(nil, value, node_position(v))
      end
    end

    #
    # Float literal
    #
    define_parser do
      rule(:float_literal) do
        (
          (dec_literal.maybe >> str('.') >> dec_literal >> exponent.maybe) |
          (dec_literal >> exponent)
        ).as(:float_literal)
      end

      rule(:exponent) do
        match('[eE]') >> (match('[+-]') >> str('_').maybe).maybe >> dec_literal
      end
    end

    define_transform do
      rule(float_literal: simple(:f)) do
        v = f.to_s.tr('_', '').to_f
        Node::Float.new(nil, v, node_position(f))
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
      rule(:ss_empty_literal) do
        ss_bq(false).as(:ss_bq) >> ss_eq('').as(:ss_eq)
      end

      rule(:ss_literal) do
        ss_bq(false).as(:ss_bq) >>
          ss_portions('').as(:ss_portions) >> ss_eq('').as(:ss_eq)
      end

      rule(:ss_empty_literal_custom_delimiters) do
        ss_bq(true).capture(:bq).as(:ss_bq) >>
          dynamic do |_, c|
            ss_eq(c.captures[:bq].to_s[0..-2]).as(:ss_eq)
          end
      end

      rule(:ss_literal_custom_delimiters) do
        ss_bq(true).capture(:bq).as(:ss_bq) >>
          dynamic do |_, c|
            pounds = c.captures[:bq].to_s[0..-2]
            ss_portions(pounds).as(:ss_portions) >> ss_eq(pounds).as(:ss_eq)
          end
      end

      rule(:ms_empty_literal) do
        ms_bq(false).as(:ms_bq) >> ms_eq('', false).as(:ms_eq)
      end

      rule(:ms_literal) do
        ms_bq(false).as(:ms_bq) >>
          ms_portions('').as(:ms_portions) >> ms_eq('', false).as(:ms_eq)
      end

      rule(:ms_empty_literal_custom_delimiters) do
        ms_bq(true).capture(:bq).as(:ms_bq) >>
          dynamic do |_, c|
            ms_eq(c.captures[:bq].to_s[0..-4], false).as(:ms_eq)
          end
      end

      rule(:ms_literal_custom_delimiters) do
        ms_bq(true).capture(:bq).as(:ms_bq) >>
          dynamic do |_, c|
            pounds = c.captures[:bq].to_s[0..-4]
            ms_portions(pounds).as(:ms_portions) >> ms_eq(pounds, false).as(:ms_eq)
          end
      end

      rule(:string_literal) do
        [
          ms_empty_literal_custom_delimiters, ms_literal_custom_delimiters,
          ms_empty_literal, ms_literal,
          ss_empty_literal_custom_delimiters, ss_literal_custom_delimiters,
          ss_empty_literal, ss_literal
        ].inject(:|)
      end

      private

      def interplation(pounds)
        str("\\#{pounds}") >> bracketed(expression, '(', ')')
      end

      def unicode_char(pounds)
        str("\\#{pounds}u") >> str('{') >> match('[\h]').repeat(1) >> str('}')
      end

      def escaped_char(pounds)
        str("\\#{pounds}") >> match('[^\(u]')
      end

      def ss_char(pounds)
        (nl | str("\\#{pounds}") | ss_eq(pounds)).absent? >> any
      end

      def ss_string(pounds)
        (unicode_char(pounds) | escaped_char(pounds) | ss_char(pounds)).repeat(1)
      end

      def ss_portions(pounds)
        (
          interplation(pounds).as(:interplation) |
          ss_string(pounds).as(:ss_string)
        ).repeat(1)
      end

      def ss_bq(custom)
        if custom
          str('#').repeat(1) >> str('"')
        else
          str('"')
        end
      end

      def ss_eq(pounds)
        str("\"#{pounds}")
      end

      def ms_char(pounds)
        (nl | str("\\#{pounds}") | ms_eq(pounds, true)).absent? >> any
      end

      def ms_string(pounds)
        (unicode_char(pounds) | escaped_char(pounds) | ms_char(pounds)).repeat(1)
      end

      def ms_portion(pounds)
        (
          interplation(pounds).as(:interplation) |
          ms_string(pounds).as(:ms_string)
        ).repeat(1)
      end

      def ms_portions(pounds)
        (ms_portion(pounds).maybe >> nl.as(:ms_nl)).repeat(1)
      end

      def ms_bq(custom)
        if custom
          str('#').repeat(1) >> str('"""') >> nl.ignore
        else
          str('"""') >> nl.ignore
        end
      end

      def ms_eq(pounds, pattern_only)
        if pattern_only
          str('"""'"#{pounds}")
        else
          match('[ \t]').repeat >> str('"""'"#{pounds}")
        end
      end
    end

    define_transform do
      rule(ss_bq: simple(:bq), ss_eq: simple(:eq)) do
        Node::String.new(nil, nil, nil, node_position(bq))
      end

      rule(ss_bq: simple(:bq), ss_portions: subtree(:portions), ss_eq: simple(:eq)) do
        Node::String.new(
          nil, nil, process_ss_portions(portions, bq),
          node_position(bq)
        )
      end

      rule(ms_bq: simple(:bq), ms_eq: simple(:eq)) do
        Node::String.new(nil, nil, nil, node_position(bq))
      end

      rule(ms_bq: simple(:bq), ms_portions: subtree(:portions), ms_eq: simple(:eq)) do
        Node::String.new(
          nil, nil, process_ms_portions(portions, bq, eq),
          node_position(bq)
        )
      end

      private

      def process_ss_portions(portions, ss_bq)
        pounds = ss_bq.to_s[0..-2]
        portions.map { process_sring_portion(_1.first, pounds) }
      end

      def process_ms_portions(portions, ms_bq, ms_eq)
        pounds = ms_bq.to_s[0..-4]
        portions
          .flat_map(&:to_a)
          .then { _1[0..-2] }
          .then { trim_leading_shapes(_1, ms_eq) }
          .map { process_sring_portion(_1, pounds) }
      end

      def trim_leading_shapes(portins, ms_eq)
        prefix = ms_eq.to_s[/^[ \t]+/]
        return portins unless prefix

        portins.map do |t, s|
          if include_bol?(s)
            [t, s.to_s.delete_prefix(prefix)]
          else
            [t, s]
          end
        end
      end

      def include_bol?(string)
        _, column = string.line_and_column
        column == 1
      end

      def process_sring_portion(portion, pounds)
        type, string = portion
        case type
        when :ss_string, :ms_string then unescape_string(string, pounds)
        when :ms_nl then "\n"
        when :interplation then string
        end
      end

      def unescape_string(string, pounds)
        string
          .to_s
          .then { unescape_unicode(_1, pounds) }
          .then { unescape_char(_1, pounds, string) }
      end

      def unescape_unicode(string, pounds)
        re = /\\#{pounds}u\{([\h]+)\}/
        string.gsub(re) { Regexp.last_match(1).to_i(16).chr(Encoding::UTF_8) }
      end

      def unescape_char(string, pounds, node)
        string.gsub(/(\\#{pounds}.)/) do |m|
          ESCAPED_CHARS[m[-1]] ||
            begin
              message = "invalid escape sequence is given: #{m}"
              parse_error(message, node_position(node))
            end
        end
      end
    end
  end
end
