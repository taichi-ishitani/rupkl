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

    specify 'a float literal should be treated as an expression' do
      expect(parser).to parse('0.0').as(float_literal(0.0))
      expect(parser).to parse('123456789.123456789').as(float_literal(123456789.123456789))
      expect(parser).to parse('123.456e7').as(float_literal(123.456e7))
      expect(parser).to parse('123.456e-7').as(float_literal(123.456e-7))
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

  describe 'member reference' do
    it 'should be parsed by expression parser' do
      expect(parser)
        .to parse('foo')
        .as(member_ref(:foo))
      expect(parser)
        .to parse('foo.bar')
        .as(member_ref(member_ref(:foo), :bar))
      expect(parser)
        .to parse('foo.bar.baz')
        .as(member_ref(member_ref(member_ref(:foo), :bar), :baz))
      expect(parser)
        .to parse('"dodo".length')
        .as(member_ref('dodo', :length))
      expect(parser)
        .to parse(spacing('foo', '.', 'bar'))
        .as(member_ref(member_ref(:foo), :bar))
      expect(parser)
        .to parse(spacing('foo', '.', 'bar', '.', 'baz'))
        .as(member_ref(member_ref(member_ref(:foo), :bar), :baz))
    end
  end

  describe 'operation' do
    describe 'subscript operation' do
      it 'should be parsed by expression parser' do
        expect(parser)
          .to parse('"foo"[0]')
          .as(subscript_op('foo', 0))

        expect(parser)
          .to parse('"foo"[bar]')
          .as(subscript_op('foo', member_ref(:bar)))

        expect(parser)
          .to parse('foo[0]')
          .as(subscript_op(member_ref(:foo), 0))

        expect(parser)
          .to parse('foo[bar]')
          .as(subscript_op(member_ref(:foo), member_ref(:bar)))

        expect(parser)
          .to parse('foo.bar[0]')
          .as(subscript_op(member_ref(member_ref(:foo), :bar), 0))

        expect(parser)
          .to parse('foo.bar[baz]')
          .as(subscript_op(member_ref(member_ref(:foo), :bar), member_ref(:baz)))

        expect(parser)
          .to parse('foo[bar][baz][0]')
          .as(subscript_op(subscript_op(subscript_op(member_ref(:foo), member_ref(:bar)), member_ref(:baz)), 0))

        expect(parser)
          .to parse('foo [bar]  [baz]  [0]')
          .as(subscript_op(subscript_op(subscript_op(member_ref(:foo), member_ref(:bar)), member_ref(:baz)), 0))
      end
    end

    describe 'unary operation' do
      it 'should be parsed by expression parser' do
        # unaryMinusExpr
        expect(parser)
          .to parse('-42')
          .as(u_op(:-, 42))
        expect(parser)
          .to parse(spacing('-', '0x42'))
          .as(u_op(:-, 0x42))
        expect(parser)
          .to parse('-123456789.123456789')
          .as(u_op(:-, 123456789.123456789))

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
        expect(parser)
          .to parse('1.2**3.4')
          .as(b_op(:**, 1.2, 3.4))
        expect(parser)
          .to parse('1.2**3.4**5.6')
          .as(b_op(:**, 1.2, b_op(:**, 3.4, 5.6)))
        expect(parser)
          .to parse(spacing('1.2', '**', '3.4', '**', '5.6'))
          .as(b_op(:**, 1.2, b_op(:**, 3.4, 5.6)))
        expect(parser)
          .to parse('1.2**3')
          .as(b_op(:**, 1.2, 3))
        expect(parser)
          .to parse('1**2.3')
          .as(b_op(:**, 1, 2.3))

        # multiplicativeExpr
        expect(parser)
          .to parse('1*2')
          .as(b_op(:*, 1, 2))
        expect(parser)
          .to parse('1.2*3.4')
          .as(b_op(:*, 1.2, 3.4))
        expect(parser)
          .to parse('1.2*3')
          .as(b_op(:*, 1.2, 3))
        expect(parser)
          .to parse('1*2.3')
          .as(b_op(:*, 1, 2.3))
        expect(parser)
          .to parse('1/2')
          .as(b_op(:/, 1, 2))
        expect(parser)
          .to parse('1.2/3.4')
          .as(b_op(:/, 1.2, 3.4))
        expect(parser)
          .to parse('1.2/3')
          .as(b_op(:/, 1.2, 3))
        expect(parser)
          .to parse('1/2.3')
          .as(b_op(:/, 1, 2.3))
        expect(parser)
          .to parse('1~/2')
          .as(b_op(:'~/', 1, 2))
        expect(parser)
          .to parse('1.2~/3.4')
          .as(b_op(:'~/', 1.2, 3.4))
        expect(parser)
          .to parse('1.2~/3')
          .as(b_op(:'~/', 1.2, 3))
        expect(parser)
          .to parse('1~/2.3')
          .as(b_op(:'~/', 1, 2.3))
        expect(parser)
          .to parse('1%2')
          .as(b_op(:%, 1, 2))
        expect(parser)
          .to parse('1.2%3.4')
          .as(b_op(:%, 1.2, 3.4))
        expect(parser)
          .to parse('1.2%3')
          .as(b_op(:%, 1.2, 3))
        expect(parser)
          .to parse('1%2.3')
          .as(b_op(:%, 1, 2.3))
        expect(parser)
          .to parse('1*2/3~/4%5')
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 1, 2), 3), 4), 5))
        expect(parser)
          .to parse('0.1*2.3/4.5~/6.7%8.9')
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 0.1, 2.3), 4.5), 6.7), 8.9))
        expect(parser)
          .to parse(spacing('1', '*', '2', '/', '3', '~/', '4', '%', '5'))
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 1, 2), 3), 4), 5))
        expect(parser)
          .to parse(spacing('0.1', '*', '2.3', '/', '4.5', '~/', '6.7', '%', '8.9'))
          .as(b_op(:%, b_op(:'~/', b_op(:/, b_op(:*, 0.1, 2.3), 4.5), 6.7), 8.9))

        # additiveExpr
        expect(parser)
          .to parse('1+2')
          .as(b_op(:+, 1, 2))
        expect(parser)
          .to parse('1.2+3.4')
          .as(b_op(:+, 1.2, 3.4))
        expect(parser)
          .to parse('1.2+3')
          .as(b_op(:+, 1.2, 3))
        expect(parser)
          .to parse('1+2.3')
          .as(b_op(:+, 1, 2.3))
        expect(parser)
          .to parse('1-2')
          .as(b_op(:-, 1, 2))
        expect(parser)
          .to parse('1.2-3.4')
          .as(b_op(:-, 1.2, 3.4))
        expect(parser)
          .to parse('1.2-3')
          .as(b_op(:-, 1.2, 3))
        expect(parser)
          .to parse('1-2.3')
          .as(b_op(:-, 1, 2.3))
        expect(parser)
          .to parse('1+2-3')
          .as(b_op(:-, b_op(:+, 1, 2), 3))
        expect(parser)
          .to parse('0.1+2.3-4.5')
          .as(b_op(:-, b_op(:+, 0.1, 2.3), 4.5))
        expect(parser)
          .to parse(spacing('1', '+', '2', '-', '3'))
          .as(b_op(:-, b_op(:+, 1, 2), 3))
        expect(parser)
          .to parse(spacing('0.1', '+', '2.3', '-', '4.5'))
          .as(b_op(:-, b_op(:+, 0.1, 2.3), 4.5))

        # comparisonExpr
        expect(parser)
          .to parse('1<2')
          .as(b_op(:<, 1, 2))
        expect(parser)
          .to parse('1.2<3.4')
          .as(b_op(:<, 1.2, 3.4))
        expect(parser)
          .to parse('1.2<3')
          .as(b_op(:<, 1.2, 3))
        expect(parser)
          .to parse('1<2.3')
          .as(b_op(:<, 1, 2.3))
        expect(parser)
          .to parse('1>2')
          .as(b_op(:>, 1, 2))
        expect(parser)
          .to parse('1.2>3.4')
          .as(b_op(:>, 1.2, 3.4))
        expect(parser)
          .to parse('1.2>3')
          .as(b_op(:>, 1.2, 3))
        expect(parser)
          .to parse('1>2.3')
          .as(b_op(:>, 1, 2.3))
        expect(parser)
          .to parse('1<=2')
          .as(b_op(:<=, 1, 2))
        expect(parser)
          .to parse('1.2<=3.4')
          .as(b_op(:<=, 1.2, 3.4))
        expect(parser)
          .to parse('1.2<=3')
          .as(b_op(:<=, 1.2, 3))
        expect(parser)
          .to parse('1<=2.3')
          .as(b_op(:<=, 1, 2.3))
        expect(parser)
          .to parse('1>=2')
          .as(b_op(:>=, 1, 2))
        expect(parser)
          .to parse('1.2>=3.4')
          .as(b_op(:>=, 1.2, 3.4))
        expect(parser)
          .to parse('1.2>=3')
          .as(b_op(:>=, 1.2, 3))
        expect(parser)
          .to parse('1>=2.3')
          .as(b_op(:>=, 1, 2.3))
        expect(parser)
          .to parse('1<2>3<=4>=5')
          .as(b_op(:>=, b_op(:<=, b_op(:>, b_op(:<, 1, 2), 3), 4), 5))
        expect(parser)
          .to parse('0.1<2.3>4.5<=6.7>=8.9')
          .as(b_op(:>=, b_op(:<=, b_op(:>, b_op(:<, 0.1, 2.3), 4.5), 6.7), 8.9))

        # equalityExpr
        expect(parser)
          .to parse('1==2')
          .as(b_op(:==, 1, 2))
        expect(parser)
          .to parse('1!=2')
          .as(b_op(:'!=', 1, 2))
        expect(parser)
          .to parse('1==2!=3')
          .as(b_op(:'!=', b_op(:==, 1, 2), 3))
        expect(parser)
          .to parse('1.0==2.0')
          .as(b_op(:==, 1.0, 2.0))
        expect(parser)
          .to parse('1.0!=2.0')
          .as(b_op(:'!=', 1.0, 2.0))
        expect(parser)
          .to parse('1.0==2.0!=3.0')
          .as(b_op(:'!=', b_op(:==, 1.0, 2.0), 3.0))

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

      specify "newline or semicolon should not precede '-' or '[]' operator" do
        expect(parser).not_to parse("1\n-2")
        expect(parser).not_to parse("1;-2")
        expect(parser).not_to parse("1\n;-2")
        expect(parser).not_to parse("1;\n-2")
        expect(parser).not_to parse("foo\n[0]")
        expect(parser).not_to parse('foo;[0]')
        expect(parser).not_to parse("foo\n;[0]")
        expect(parser).not_to parse("foo;\n[0]")
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
        .to parse('1<2==3').as(b_op(:==, b_op(:<, 1, 2), 3))
      expect(parser)
        .to parse('1<(2==3)').as(b_op(:<, 1, b_op(:==, 2, 3)))

      expect(parser)
        .to parse('1==2&&3').as(b_op(:'&&', b_op(:==, 1, 2), 3))
      expect(parser)
        .to parse('1==(2&&3)').as(b_op(:==, 1, b_op(:'&&', 2, 3)))

      expect(parser)
        .to parse('1&&2||3').as(b_op(:'||', b_op(:'&&', 1, 2), 3))
      expect(parser)
        .to parse('1&&(2||3)').as(b_op(:'&&', 1, b_op(:'||', 2, 3)))
    end
  end
end
