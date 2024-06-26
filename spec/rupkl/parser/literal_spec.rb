# frozen_string_literal: true

RSpec.describe RuPkl::Parser do
  def random_upcase(string)
    pos =
      (0...string.size)
        .to_a
        .select { |i| /[a-z]/i =~ string[i] }
        .sample((1..string.size).to_a.sample)
    string
      .dup.tap { |s| pos.each { |i| s[i] = s[i].upcase } }
  end

  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'boolean lieral' do
    def parse(string)
      parse_string(string, :boolean_literal)
    end

    it 'should be parsed by boolean_literal parser' do
      expect(parser).to parse('true').as(boolean_literal(true))
      expect(parser).to parse('false').as(boolean_literal(false))
    end

    it 'should be case sensitive' do
      ['true', 'false'].each do |value|
        expect(parser).not_to parse(value.upcase)
        expect(parser).not_to parse(random_upcase(value))
      end
    end
  end

  describe 'integer literal' do
    def parse(string)
      parse_string(string, :int_literal)
    end

    it 'should be parsed by int_literal parser' do
      # decimal literal
      expect(parser).to parse('0').as(int_literal(0))
      expect(parser).to parse('42').as(int_literal(42))
      expect(parser).to parse('00').as(int_literal(0))
      expect(parser).to parse('00042').as(int_literal(42))
      expect(parser).to parse('123456789123456789').as(int_literal(123456789123456789))
      expect(parser).to parse('9223372036854775807').as(int_literal(9223372036854775807))
      expect(parser).to parse('1_000').as(int_literal(1000))
      expect(parser).to parse('1_000__000').as(int_literal(1000000))
      expect(parser).to parse('1___').as(int_literal(1))
      expect(parser).to parse('1___1').as(int_literal(11))
      expect(parser).to parse('1__000_0').as(int_literal(10000))

      # hex literal
      expect(parser).to parse('0x42').as(int_literal(0x42))
      expect(parser).to parse('0x123456789abcdef').as(int_literal(0x123456789abcdef))
      expect(parser).to parse('0x123456789ABCDEF').as(int_literal(0x123456789ABCDEF))
      expect(parser).to parse('0x123456789aBcDeF').as(int_literal(0x123456789aBcDeF))
      expect(parser).to parse('0x000123456789abcdef').as(int_literal(0x000123456789abcdef))
      expect(parser).to parse('0x000123456789abcdef').as(int_literal(0x000123456789abcdef))
      expect(parser).to parse('0x42_ab_AB_de_12').as(int_literal(0x42abABde12))
      expect(parser).to parse('0x41__').as(int_literal(0x41))
      expect(parser).to parse('0x59__9').as(int_literal(0x599))

      # binary literal
      expect(parser).to parse('0b101101').as(int_literal(0b101101))
      expect(parser).to parse('0b000101101').as(int_literal(0b000101101))
      expect(parser).to parse('0b1011_0110').as(int_literal(0b10110110))
      expect(parser).to parse('0b01__10').as(int_literal(0b0110))
      expect(parser).to parse('0b1____0').as(int_literal(0b10))

      # octal literal
      expect(parser).to parse('0o01234567').as(int_literal(0o01234567))
      expect(parser).to parse('0o76543210').as(int_literal(0o76543210))
      expect(parser).to parse('0o1234_5670').as(int_literal(0o12345670))
      expect(parser).to parse('0o45__67').as(int_literal(0o4567))
      expect(parser).to parse('0o7____0').as(int_literal(0o70))
      expect(parser).to parse('0o644').as(int_literal(0o644))
      expect(parser).to parse('0o755').as(int_literal(0o755))
    end

    it 'should not parse literals having underscores at head' do
      expect(parser).not_to parse('_1000')
      expect(parser).not_to parse('__1000')
      expect(parser).not_to parse('0x_41')
      expect(parser).not_to parse('0x__41')
      expect(parser).not_to parse('0b_10')
      expect(parser).not_to parse('0b__10')
      expect(parser).not_to parse('0o_4567')
      expect(parser).not_to parse('0o__4567')
    end

    specify 'lower case prefixes are only allowed' do
      expect(parser).not_to parse('0X41')
      expect(parser).not_to parse('0B10')
      expect(parser).not_to parse('0O4567')
    end
  end

  describe 'float literal' do
    def parse(string)
      parse_string(string, :float_literal)
    end

    it 'should be parsed by float_literal parser' do
      expect(parser).to parse('0.0').as(float_literal(0.0))
      expect(parser).to parse('.0').as(float_literal(0.0))
      expect(parser).to parse('1.0').as(float_literal(1.0))
      expect(parser).to parse('0.1').as(float_literal(0.1))
      expect(parser).to parse('.1').as(float_literal(0.1))
      expect(parser).to parse('1e1').as(float_literal(10.0))
      expect(parser).to parse('1e-1').as(float_literal(0.1))
      expect(parser).to parse('1e-_1').as(float_literal(0.1))
      expect(parser).to parse('123456789.123456789').as(float_literal(123456789.123456789))
      expect(parser).to parse('123.456e7').as(float_literal(123.456e7))
      expect(parser).to parse('123.456e-7').as(float_literal(123.456e-7))
      expect(parser).to parse('4.9E-324').as(float_literal(4.9E-324))
      expect(parser).to parse('1.7976931348623157E308').as(float_literal(1.7976931348623157E308))
      expect(parser).to parse('123_456_789.123_456_789').as(float_literal(123456789.123456789))
      expect(parser).to parse('1____.1____').as(float_literal(1.1))
      expect(parser).to parse('1____1.1____1').as(float_literal(11.11))
      expect(parser).to parse('123.4_56e7').as(float_literal(123.456e7))
      expect(parser).to parse('123.4_56e-7').as(float_literal(123.456e-7))
      expect(parser).to parse('123.456e1_0').as(float_literal(123.456e10))
      expect(parser).to parse('1_23.456e-1_0').as(float_literal(123.456e-10))
    end

    specify 'underscore should not be before \'.\' character' do
      expect(parser).not_to parse('1._0')
      expect(parser).not_to parse('._0')
    end

    specify 'underscore should not be after e/E exponent symbol' do
      expect(parser).not_to parse('1e_1')
      expect(parser).not_to parse('1E_1')
    end
  end

  describe 'string literal' do
    def parse(string)
      parse_string(string, :string_literal)
    end

    describe 'single line string literal' do
      it 'should be parsed by string_literal parser' do
        expect(parser).to parse('""').as(empty_string_literal)
        expect(parser).to parse('"Hello, World!"').as(ss_literal('Hello, World!'))
      end

      specify 'tab, line feed, carriage return, verbatim quote and verbatim backslash characters are escaped' do
        expect(parser).to parse('"\\\\\\"\\\\("').as(ss_literal('\"\('))
        expect(parser).to parse('"\t\r\n"').as(ss_literal("\t\r\n"))
      end

      it 'can include escaped unicode code points' do
        expect(parser)
          .to parse('"\u{26} \u{E9} \u{1F600}"')
          .as(ss_literal('& é 😀'))
        expect(parser)
          .to parse('"\u{9}\u{30}\u{100}\u{1000}\u{10000}\u{010000}\u{0010000}\u{00010000}"')
          .as(ss_literal("\t0Āက𐀀𐀀𐀀𐀀"))
      end

      it 'can include interpolations' do
        expect(parser).to parse('"\(str1) are \(str2) today? Are \(str2) hungry?"')
          .as(ss_literal(
            member_ref(:str1), ' are ', member_ref(:str2),
            ' today? Are ', member_ref(:str2), ' hungry?'
          ))

        expect(parser).to parse('"Can \(str2 + " nest \(str3)") for me?"')
          .as(ss_literal(
            'Can ',
            b_op(:+, member_ref(:str2), ss_literal(' nest ', member_ref(:str3))),
            ' for me?'
          ))

        expect(parser).to parse('"\(42)"')
          .as(ss_literal(int_literal(42)))

        expect(parser).to parse('"\(40 + 2)"')
          .as(ss_literal(b_op(:+, 40, 2)))

        expect(parser).to parse('"\(1.23)"')
          .as(ss_literal(float_literal(1.23)))

        expect(parser).to parse('"\("Pigion")"')
          .as(ss_literal(ss_literal('Pigion')))

        expect(parser).to parse('"\(false)"')
          .as(ss_literal(boolean_literal(false)))
      end

      it 'should not have an unescaped newline' do
        expect(parser).not_to parse("\"\n\"")
        expect(parser).not_to parse("\"foo\nbar\"")
      end

      specify 'string delimiters and escape characters can be customized' do
        expect(parser)
          .to parse('#""#')
          .as(empty_string_literal)
        expect(parser)
          .to parse('##""##')
          .as(empty_string_literal)
        expect(parser)
          .to parse('###""###')
          .as(empty_string_literal)
        expect(parser)
          .to parse('#"\r\n\t\\\\"#')
          .as(ss_literal('\r\n\t\\\\'))
        expect(parser)
          .to parse('#"$foo"#')
          .as(ss_literal('$foo'))
        expect(parser)
          .to parse('##"# ## ### " "" """ \ \#"##')
          .as(ss_literal('# ## ### " "" """ \\ \\#'))
        expect(parser)
          .to parse('###"# ## ### #### " "" """ """" \ \# \##"###')
          .as(ss_literal('# ## ### #### " "" """ """" \\ \\# \\##'))
        expect(parser)
          .to parse('#"\#u{61} \#u{1F920}"#')
          .as(ss_literal('a 🤠'))
        expect(parser)
          .to parse('###"\###u{61} \###u{1F920}"###')
          .as(ss_literal('a 🤠'))
      end
    end

    describe 'multiline string literal' do
      it 'should be parsed by string_literal parser' do
        pkl = <<~'PKL'
          """
          """
        PKL
        expect(parser).to parse(pkl).as(empty_string_literal)

        pkl = <<~'PKL'
        """
            """
        PKL
        expect(parser).to parse(pkl).as(empty_string_literal)

        pkl = <<~'PKL'
          """

          """
        PKL
        expect(parser).to parse(pkl).as(ms_literal("\n"))

        pkl = <<~'PKL'
          """


          """
        PKL
        expect(parser).to parse(pkl).as(ms_literal("\n\n"))

        pkl = <<~'PKL'
          """
          Although the Dodo is extinct,
          the species will be remembered.
          """
        PKL
        out = <<~OUT
          Although the Dodo is extinct,
          the species will be remembered.
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))
      end

      specify 'tab, line feed, carriage return, verbatim quote and verbatim backslash characters are escaped' do
        pkl = <<~'PKL'
          """
          \\\"\\(
          """
        PKL
        out = <<~'OUT'
          \"\(
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))

        pkl = <<~'PKL'
          """
          \t\r\n
          """
        PKL
        out = <<~OUT
          \t\r\n
        OUT
        expect(parser).to parse(pkl).as(string_literal(out.chomp))
      end

      it 'can include escaped unicode code points' do
        pkl = <<~'PKL'
          """
          \u{9}\u{30}\u{100}\u{1000}\u{10000}\u{010000}\u{0010000}\u{00010000}
          """
        PKL
        out = <<~OUT
          \t0Āက𐀀𐀀𐀀𐀀
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))
      end

      it 'can include interpolations' do
        pkl = <<~'PKL'
          """
          How are you today?
          Are \(str2) hungry?
          Can \(str2 + " nest \(str3)") for me?
          """
        PKL
        expect(parser).to parse(pkl)
          .as(ms_literal(
            "How are you today?\nAre ", member_ref(:str2), " hungry?\nCan ",
            b_op(:+, member_ref(:str2), ss_literal(' nest ', member_ref(:str3))),
            ' for me?'
          ))
      end

      specify 'leading whitespaces should be trimmed' do
        pkl = <<~'PKL'
          """
            leading
            whitespace
            partially
            trimmed
            """
        PKL
        out = <<~'OUT'
          leading
          whitespace
          partially
          trimmed
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))

        pkl = <<~'PKL'
          """
            leading
              whitespace
                partially
                  trimmed
            """
        PKL
        out = <<~'OUT'
          leading
            whitespace
              partially
                trimmed
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))

        pkl = <<~'PKL'
          """
            leading
              whitespace
                partially
                  trimmed
          """
        PKL
        out = <<~'OUT'.tr('|', '')
          |  leading
          |    whitespace
          |      partially
          |        trimmed
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))
      end

      specify 'string delimiters and escape characters can be customized' do
        pkl = <<~'PKL'
          #"""
          """#
        PKL
        expect(parser).to parse(pkl).as(empty_string_literal)

        pkl = <<~'PKL'
          ###"""

          """###
        PKL
        expect(parser).to parse(pkl).as(ms_literal("\n"))

        pkl = <<~'PKL'
          #"""
          \#r\#n\#t\#\\#"
          """#
        PKL
        out = <<~OUT
          \r\n\t\\"
        OUT
        expect(parser).to parse(pkl).as(string_literal(out.chomp))

        pkl = <<~'PKL'
          ##"""
          # ## ### " "" """ \ \#
          \##u{61} \##u{1F920}
          """##
        PKL
        out = <<~'OUT'
          # ## ### " "" """ \ \#
          a 🤠
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))

        pkl = <<~'PKL'
          #####"""
          # ## ### #### ##### ###### " "" """ """" """"" \ \# \## \### \####
          \#####u{61} \#####u{1F920}
          """#####
        PKL
        out = <<~'OUT'
          # ## ### #### ##### ###### " "" """ """" """"" \ \# \## \### \####
          a 🤠
        OUT
        expect(parser).to parse(pkl).as(ms_literal(out))
      end
    end

    context 'invalid escape sequence is given' do
      it 'should raise ParseError' do
        expect { parser.parse('"\ab"', root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \a'
        expect { parser.parse('"\12"', root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \1'
        expect { parser.parse('"\{"', root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \{'

        pkl = <<~'PKL'.chomp
          """
          \ab
          """
        PKL
        expect { parser.parse(pkl, root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \a'

        pkl = <<~'PKL'.chomp
          """
          \12
          """
        PKL
        expect { parser.parse(pkl, root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \1'

        pkl = <<~'PKL'.chomp
          """
          \{}
          """
        PKL
        expect { parser.parse(pkl, root: :string_literal) }
          .to raise_parse_error 'invalid escape sequence is given: \{'
      end
    end
  end
end
