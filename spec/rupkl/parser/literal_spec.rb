# frozen_string_literal: true

RSpec.describe RuPkl::Parser, :parser do
  def random_upcase(string)
    pos =
      (0...string.size)
        .to_a
        .select { |i| /[a-z]/i =~ string[i] }
        .sample((1..string.size).to_a.sample)
    string
      .dup.tap { |s| pos.each { |i| s[i] = s[i].upcase } }
  end

  describe 'boolean lieral' do
    let(:parser) do
      RuPkl::Parser.new(:boolean_literal)
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
    let(:parser) do
      RuPkl::Parser.new(:integer_literal)
    end

    it 'should be parsed by integer_literal parser' do
      # decimal literal
      expect(parser).to parse('42').as(integer_literal(42))
      expect(parser).to parse('00042').as(integer_literal(42))
      expect(parser).to parse('123456789123456789').as(integer_literal(123456789123456789))
      expect(parser).to parse('-42').as(integer_literal(-42))
      expect(parser).to parse('-00042').as(integer_literal(-00042))
      expect(parser).to parse('-123456789123456789').as(integer_literal(-123456789123456789))
      expect(parser).to parse('-9223372036854775808').as(integer_literal(-9223372036854775808))
      expect(parser).to parse('9223372036854775807').as(integer_literal(9223372036854775807))
      expect(parser).to parse('1_000').as(integer_literal(1000))
      expect(parser).to parse('1_000__000').as(integer_literal(1000000))
      expect(parser).to parse('1___').as(integer_literal(1))
      expect(parser).to parse('1___1').as(integer_literal(11))
      expect(parser).to parse('1__000_0').as(integer_literal(10000))
      expect(parser).to parse('-10_000').as(integer_literal(-10000))

      # hex literal
      expect(parser).to parse('0x42').as(integer_literal(0x42))
      expect(parser).to parse('0x123456789abcdef').as(integer_literal(0x123456789abcdef))
      expect(parser).to parse('0x123456789ABCDEF').as(integer_literal(0x123456789ABCDEF))
      expect(parser).to parse('0x123456789aBcDeF').as(integer_literal(0x123456789aBcDeF))
      expect(parser).to parse('0x000123456789abcdef').as(integer_literal(0x000123456789abcdef))
      expect(parser).to parse('0x000123456789abcdef').as(integer_literal(0x000123456789abcdef))
      expect(parser).to parse('-0x42').as(integer_literal(-0x42))
      expect(parser).to parse('-0x123456789abcdef').as(integer_literal(-0x123456789abcdef))
      expect(parser).to parse('-0x123456789ABCDEF').as(integer_literal(-0x123456789ABCDEF))
      expect(parser).to parse('-0x123456789aBcDeF').as(integer_literal(-0x123456789aBcDeF))
      expect(parser).to parse('-0x000123456789abcdef').as(integer_literal(-0x000123456789abcdef))
      expect(parser).to parse('0x42_ab_AB_de_12').as(integer_literal(0x42abABde12))
      expect(parser).to parse('0x41__').as(integer_literal(0x41))
      expect(parser).to parse('0x59__9').as(integer_literal(0x599))
      expect(parser).to parse('-0x59__9').as(integer_literal(-0x599))

      # binary literal
      expect(parser).to parse('0b101101').as(integer_literal(0b101101))
      expect(parser).to parse('0b000101101').as(integer_literal(0b000101101))
      expect(parser).to parse('-0b101101').as(integer_literal(-0b101101))
      expect(parser).to parse('-0b000101101').as(integer_literal(-0b000101101))
      expect(parser).to parse('0b1011_0110').as(integer_literal(0b10110110))
      expect(parser).to parse('0b01__10').as(integer_literal(0b0110))
      expect(parser).to parse('0b1____0').as(integer_literal(0b10))
      expect(parser).to parse('-0b1_____').as(integer_literal(-0b1))

      # octal literal
      expect(parser).to parse('0o01234567').as(integer_literal(0o01234567))
      expect(parser).to parse('0o76543210').as(integer_literal(0o76543210))
      expect(parser).to parse('-0o01234567').as(integer_literal(-0o01234567))
      expect(parser).to parse('-0o76543210').as(integer_literal(-0o76543210))
      expect(parser).to parse('0o1234_5670').as(integer_literal(0o12345670))
      expect(parser).to parse('0o45__67').as(integer_literal(0o4567))
      expect(parser).to parse('0o7____0').as(integer_literal(0o70))
      expect(parser).to parse('-0o7_____').as(integer_literal(-0o7))
      expect(parser).to parse('0o644').as(integer_literal(0o644))
      expect(parser).to parse('0o755').as(integer_literal(0o755))
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
end
