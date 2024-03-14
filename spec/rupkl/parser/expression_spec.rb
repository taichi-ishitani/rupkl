# frozen_string_literal: true

RSpec.describe RuPkl::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parse_string(string, :expression)
  end

  def spacing(*portions)
    portions.inject do |r, i|
      ws =
        case i
        when '-' then ['', ' ', "\t", "\f"]
        else ['', ' ', "\t", "\f", "\r", "\n", ';']
        end
      r + ws.sample([1, 2, 3].sample).join + i
    end
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

  describe 'operation' do
    describe 'unary operation' do
      it 'should be parsed by expression parser' do
        # unaryMinusExpr
        expect(parser)
          .to parse('-42')
          .as(u_op(:-, 42))
        expect(parser)
          .to parse(spacing('-', '0x42'))
          .as(u_op(:-, 0x42))

        # logicalNotExpr
        expect(parser)
          .to parse('!true')
          .as(u_op(:!, true))
        expect(parser)
          .to parse(spacing('!', 'false'))
          .as(u_op(:!, false))
      end
    end

    describe 'binary operation' do
      it 'should be parsed by expression parser' do
        # exponentiationExpr
        expect(parser)
          .to parse('1**2')
          .as(b_op(:**, 1, 2))
        expect(parser)
          .to parse('1**2**3')
          .as(b_op(:**, 1, b_op(:**, 2, 3)))
        expect(parser)
          .to parse(spacing('1', '**', '2', '**', '3'))
          .as(b_op(:**, 1, b_op(:**, 2, 3)))

        # multiplicativeExpr
        expect(parser)
          .to parse('1*2')
          .as(b_op(:*, 1, 2))
        expect(parser)
          .to parse('1/2')
          .as(b_op(:/, 1, 2))
        expect(parser)
          .to parse('1~/2')
          .as(b_op(:'~/', 1, 2))
        expect(parser)
          .to parse('1%2')
          .as(b_op(:%, 1, 2))
        expect(parser)
          .to parse('1*2/3~/4%5')
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 1, 2), 3), 4), 5))
        expect(parser)
          .to parse(spacing('1', '*', '2', '/', '3', '~/', '4', '%', '5'))
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 1, 2), 3), 4), 5))

        # additiveExpr
        expect(parser)
          .to parse('1+2')
          .as(b_op(:+, 1, 2))
        expect(parser)
          .to parse('1-2')
          .as(b_op(:-, 1, 2))
        expect(parser)
          .to parse('1+2-3')
          .as(b_op(:-, b_op(:+, 1, 2), 3))
        expect(parser)
          .to parse(spacing('1', '+', '2', '-', '3'))
          .as(b_op(:-, b_op(:+, 1, 2), 3))

        # comparisonExpr
        expect(parser)
          .to parse('1<2')
          .as(b_op(:<, 1, 2))
        expect(parser)
          .to parse('1>2')
          .as(b_op(:>, 1, 2))
        expect(parser)
          .to parse('1<=2')
          .as(b_op(:<=, 1, 2))
        expect(parser)
          .to parse('1>=2')
          .as(b_op(:>=, 1, 2))
        expect(parser)
          .to parse('1<2>3<=4>=5')
          .as(b_op(:>=, b_op(:<=, b_op(:>, b_op(:<, 1, 2), 3), 4), 5))

        # logicalAndExpr
        expect(parser)
          .to parse('1&&2')
          .as(b_op(:'&&', 1, 2))
        expect(parser)
          .to parse(spacing('1', '&&', '2'))
          .as(b_op(:'&&', 1, 2))

        # logicalOrExpr
        expect(parser)
          .to parse('1||2')
          .as(b_op(:'||', 1, 2))
        expect(parser)
          .to parse(spacing('1', '||', '2'))
          .as(b_op(:'||', 1, 2))
      end

      specify "newline or semicolon should not precede the '-' operator" do
        expect(parser).not_to parse("1\n-2")
        expect(parser).not_to parse("1;-2")
        expect(parser).not_to parse("1\n;-2")
        expect(parser).not_to parse("1;\n-2")
      end
    end

    specify 'operators have certain precedence' do
      expect(parser)
        .to parse('-1**2').as(b_op(:**, u_op(:-, 1), 2))
      expect(parser)
        .to parse('-(1**2)').as(u_op(:-, b_op(:**, 1, 2)))

      expect(parser)
        .to parse('!1**2').as(b_op(:**, u_op(:!, 1), 2))
      expect(parser)
        .to parse('!(1**2)').as(u_op(:!, b_op(:**, 1, 2)))

      expect(parser)
        .to parse('1**2*3').as(b_op(:*, b_op(:**, 1, 2), 3))
      expect(parser)
        .to parse('1**(2*3)').as(b_op(:**, 1, b_op(:*, 2, 3)))

      expect(parser)
        .to parse('1*2+3').as(b_op(:+, b_op(:*, 1, 2), 3))
      expect(parser)
        .to parse('1*(2+3)').as(b_op(:*, 1, b_op(:+, 2, 3)))

      expect(parser)
        .to parse('1+2<3').as(b_op(:<, b_op(:+, 1, 2), 3))
      expect(parser)
        .to parse('1+(2<3)').as(b_op(:+, 1, b_op(:<, 2, 3)))

      expect(parser)
        .to parse('1<2&&3').as(b_op(:'&&', b_op(:<, 1, 2), 3))
      expect(parser)
        .to parse('1<(2&&3)').as(b_op(:<, 1, b_op(:'&&', 2, 3)))

      expect(parser)
        .to parse('1&&2||3').as(b_op(:'||', b_op(:'&&', 1, 2), 3))
      expect(parser)
        .to parse('1&&(2||3)').as(b_op(:'&&', 1, b_op(:'||', 2, 3)))
    end
  end
end
