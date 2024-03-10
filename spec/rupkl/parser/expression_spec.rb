# frozen_string_literal: true

RSpec.describe RuPkl::Parser, :parser do
  let(:parser) do
    RuPkl::Parser.new(:expression)
  end

  def spacing(*portions, excluded_ws: nil)
    ws =
      ['', ' ', "\t", "\f", "\r", "\n", ';'] - Array(excluded_ws)
    portions
      .inject { |r, i| r + ws.sample([1, 2, 3].sample).join + i }
  end

  describe 'literals' do
    specify 'a boolean literal should be treated as an expression' do
      expect(parser).to parse('true').as(boolean_literal(true))
      expect(parser).to parse('false').as(boolean_literal(false))
    end

    specify 'a integer literal should be treated as an expression' do
      expect(parser).to parse('42').as(integer_literal(42))
      expect(parser).to parse('0x42').as(integer_literal(0x42))
      expect(parser).to parse('0b101101').as(integer_literal(0b101101))
      expect(parser).to parse('0o01234567').as(integer_literal(0o01234567))
    end

    specify 'a string literal should be treated as an expression' do
      pkl = '"Hello, World!"'
      out = 'Hello, World!'
      expect(parser).to parse(pkl).as(ss_literal(out))

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
  end

  describe 'unary operation' do
    it 'should be parsed by expression parser' do
      # unaryMinusExpr
      expect(parser)
        .to parse('-42')
        .as(u_op(:-, integer_literal(42)))
      expect(parser)
        .to parse(spacing('-', '0x42'))
        .as(u_op(:-, integer_literal(0x42)))

      # logicalNotExpr
      expect(parser)
        .to parse('!true')
        .as(u_op(:!, boolean_literal(true)))
      expect(parser)
        .to parse(spacing('!', 'false'))
        .as(u_op(:!, boolean_literal(false)))
    end
  end
end
