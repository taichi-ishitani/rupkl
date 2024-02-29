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
end
