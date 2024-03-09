# frozen_string_literal: true

RSpec.describe RuPkl::Parser, :parser do
  let(:parser) do
    RuPkl::Parser.new(:id)
  end

  describe 'regular identifier' do
    it 'should be parsed by id parser' do
      id = 'my_identifier'
      expect(parser).to parse(id).as(identifer(id))

      id = 'My_IdEnTiFiEr'
      expect(parser).to parse(id).as(identifer(id))

      id = 'x'
      expect(parser).to parse(id).as(identifer(id))

      id = '_y0123'
      expect(parser).to parse(id).as(identifer(id))

      id = '$y0123'
      expect(parser).to parse(id).as(identifer(id))

      id = '_3'
      expect(parser).to parse(id).as(identifer(id))

      id = '$3'
      expect(parser).to parse(id).as(identifer(id))

      id = '_'
      expect(parser).to parse(id).as(identifer(id))

      id = '$'
      expect(parser).to parse(id).as(identifer(id))

      id = 'ほげ'
      expect(parser).to parse(id).as(identifer(id))
    end

    specify 'keywords cannot be used for regular identifier' do
      RuPkl::Parser::KEYWORDS.each do |keyword|
        next if /[\W]$/ =~ keyword

        expect { parser.parse(keyword) }
          .to raise_parse_error "keyword '#{keyword}' is not allowed for identifier"
      end
    end

    specify 'reserved keywords cannot be used for regular identifier' do
      RuPkl::Parser::RESERVED_KEYWORDS.each do |keyword|
        expect { parser.parse(keyword) }
          .to raise_parse_error "keyword '#{keyword}' is not allowed for identifier"
      end
    end
  end

  describe 'quoted identifier' do
    it 'should be parsed by id parser' do
      id = "A Bird's First Flight Time"
      expect(parser).to parse("`#{id}`").as(identifer(id))

      id = "A Bird's First \nFlight Time"
      expect(parser).to parse("`#{id}`").as(identifer(id))

      id = '0123'
      expect(parser).to parse("`#{id}`").as(identifer(id))

      id = 'y0123$'
      expect(parser).to parse("`#{id}`").as(identifer(id))
    end

    specify 'keywords can be used for quoted identifier' do
      RuPkl::Parser::KEYWORDS.each do |keyword|
        expect(parser).to parse("`#{keyword}`").as(identifer(keyword))
      end
    end

    specify 'reserved keywords can be used for quoted identifier' do
      RuPkl::Parser::RESERVED_KEYWORDS.each do |keyword|
        expect(parser).to parse("`#{keyword}`").as(identifer(keyword))
      end
    end
  end
end
