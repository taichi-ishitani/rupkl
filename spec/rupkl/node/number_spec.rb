# frozen_string_literal: true

RSpec.describe RuPkl::Node::Number do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:int_value) do
    rand(0..1000)
  end

  let(:float_value) do
    rand(1E-3..1E3)
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parser.parse(int_value.to_s, root: :int_literal)
      expect(node.evaluate(nil)).to be node

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.evaluate(nil)).to be node
    end
  end

  describe '#to_ruby' do
    it 'should return its value' do
      node = parser.parse(int_value.to_s, root: :int_literal)
      expect(node.to_ruby(nil)).to eq int_value

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.to_ruby(nil)).to eq float_value
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing its value' do
      node = parser.parse(int_value.to_s, root: :int_literal)
      expect(node.to_string(nil)).to eq int_value.to_s
      expect(node.to_pkl_string(nil)).to eq int_value.to_s

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.to_string(nil)).to eq float_value.to_s
      expect(node.to_pkl_string(nil)).to eq float_value.to_s
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parser.parse("#{int_value}[0]", root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Int type'

      node = parser.parse("#{float_value}[0]", root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Float type'
    end
  end

  describe 'unary operation' do
    context 'when the given operator is defined' do
      it 'should execute the given operation' do
        node = parser.parse('-1', root: :expression)
        expect(node.evaluate(nil)).to be_int(-1)

        node = parser.parse('-1.0', root: :expression)
        expect(node.evaluate(nil)).to be_float(-1.0)
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluatedError' do
        node = parser.parse('!1', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!\' is not defined for Int type'

        node = parser.parse('!1.0', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!\' is not defined for Float type'
      end
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      it 'should execute the given operation' do
        # equality
        ['2==2', '2.0==2.0', '2==2.0', '2.0==2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        [
          '2==3', '2.0==3.0', '2==3.0', '2.0==3',
          '2==true', '2=="foo"', '2==new Dynamic{}', '2==new Mapping{}',
          '2.0==true', '2.0=="foo"', '2.0==new Dynamic{}', '2.0==new Mapping{}'
        ].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # inequality
        [
          '2!=3', '2.0!=3.0', '2!=3.0', '2.0!=3',
          '2!=true', '2!="foo"',
          '2!=new Dynamic{}', '2!=new Mapping{}', '2!= new Listing{}',
          '2.0!=true', '2.0!="foo"',
          '2.0!=new Dynamic{}', '2.0!=new Mapping{}', '2.0!=new Listing{}'
        ].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['2!=2', '2.0!=2.0', '2!=2.0', '2.0!=2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # greater than
        ['3>2', '3.0>2.0', '3>2.0', '3.0>2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['2>3', '2.0>3.0', '2>3.0', '2.0>3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # less than
        ['2<3', '2.0<3.0', '2<3.0', '2.0<3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['3<2', '3.0<2.0', '3<2.0', '3.0<2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # greater than or equal
        ['2>=2', '3>=2', '2.0>=2.0', '3.0>=2.0', '2>=2.0', '3>=2.0', '2.0>=2', '3.0>=2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['2>=3', '2.0>=3.0', '2>=3.0', '2.0>=3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # less than or equal
        ['2<=2', '2<=3', '2.0<=2.0', '2.0<=3.0', '2<=2.0', '2<=3.0', '2.0<=2', '2.0<=3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['3<=2', '3.0<=2.0', '3<=2.0', '3.0<=2'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # addition
        [['1+2', 3], ['1.0+2.0', 3.0], ['1+2.0', 3.0], ['1.0+2', 3.0]].each do |(pkl, result)|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_number(result)
        end

        # subtraction
        [['2-3', -1], ['2.0-3.0', -1.0], ['2-3.0', -1.0], ['2.0-3', -1.0]].each do |(pkl, result)|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_number(result)
        end

        # multiplication
        [['3*4', 12], ['3.0*4.0', 12.0], ['3*4.0', 12.0], ['3.0*4', 12.0]].each do |(pkl, result)|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_number(result)
        end

        # division
        ['4/3', '4.0/3.0', '4/3.0', '4.0/3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_float(4.0/3.0)
        end

        # int division
        ['4~/3', '4.0~/3.0', '4~/3.0', '4.0~/3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_int(1)
        end

        # remainder
        [['5%6', 5], ['5.0%6.0', 5.0], ['5%6.0', 5.0], ['5.0%6', 5.0]].each do |(pkl, result)|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_number(result)
        end

        # power
        [['2**4', 16], ['2.0**4.0', 16.0], ['2**4.0', 16.0], ['2.0**4', 16.0]].each do |(pkl, result)|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_number(result)
        end
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        node = parser.parse('1||true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for Int type'

        node = parser.parse('1.0||true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for Float type'

        node = parser.parse('1&&true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Int type'

        node = parser.parse('1.0&&true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Float type'
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-', '*', '/', '~/', '%', '**'
        ].each do |op|
          node = parser.parse("1#{op}true", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

          node = parser.parse("1.0#{op}true", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

          node = parser.parse("1#{op}\"foo\"", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

          node = parser.parse("1.0#{op}\"foo\"", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end
      end
    end
  end

  describe 'properties' do
    describe 'sign' do
      it 'should return 0 for 0' do
        node = parser.parse('0.sign', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).sign', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('0.0.sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(-0.0)
      end

      it 'should return NaN for NaN' do
        node = parser.parse('NaN.sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)
      end

      it 'should return 1 for positive numbers' do
        node = parser.parse('123.sign', root: :expression)
        expect(node.evaluate(nil)).to be_int(1)

        node = parser.parse('2.34.sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(1.0)

        node = parser.parse('Infinity.sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(1.0)
      end

      it 'should return -1 for negative numbers' do
        node = parser.parse('(-123).sign', root: :expression)
        expect(node.evaluate(nil)).to be_int(-1)

        node = parser.parse('(-2.34).sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(-1.0)

        node = parser.parse('(-Infinity).sign', root: :expression)
        expect(node.evaluate(nil)).to be_float(-1.0)
      end
    end

    describe 'abs' do
      it 'should return its absolute value' do
        node = parser.parse('0.abs', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).abs', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.abs', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('(-123).abs', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('-123.abs', root: :expression)
        expect(node.evaluate(nil)).to be_int(-123)

        node = parser.parse('0.0.abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('2.34.abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.34)

        node = parser.parse('(-2.34).abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.34)

        node = parser.parse('NaN.abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)

        node = parser.parse('Infinity.abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)

        node = parser.parse('(-Infinity).abs', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)
      end
    end

    describe 'ceil' do
      it 'should round its number to the next mathematical integer towards Infinity' do
        node = parser.parse('0.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('(-123).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_int(-123)

        node = parser.parse('0.0.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(-0.0)

        node = parser.parse('2.34.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(3.0)

        node = parser.parse('2.9.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(3.0)

        node = parser.parse('(-2.34).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(-2.0)

        node = parser.parse('(-2.9).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(-2.0)

        node = parser.parse('NaN.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)

        node = parser.parse('Infinity.ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)

        node = parser.parse('(-Infinity).ceil', root: :expression)
        expect(node.evaluate(nil)).to be_float(-Float::INFINITY)
      end
    end

    describe 'floor' do
      it 'should round its number to the next mathematical integer towards -Infinity' do
        node = parser.parse('0.floor', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).floor', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.floor', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('(-123).floor', root: :expression)
        expect(node.evaluate(nil)).to be_int(-123)

        node = parser.parse('0.0.floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(-0.0)

        node = parser.parse('2.34.floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.0)

        node = parser.parse('2.9.floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.0)

        node = parser.parse('(-2.34).floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(-3.0)

        node = parser.parse('(-2.9).floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(-3.0)

        node = parser.parse('NaN.floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)

        node = parser.parse('Infinity.floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)

        node = parser.parse('(-Infinity).floor', root: :expression)
        expect(node.evaluate(nil)).to be_float(-Float::INFINITY)
      end
    end

    describe 'isPositive' do
      it 'should tell if its value is greater than or equal to zero' do
        node = parser.parse('0.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('42.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42).isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('0.0.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-0.0).isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('42.123.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42.123).isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('NaN.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('Infinity.isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-Infinity).isPositive', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)
      end
    end

    describe 'isFinite' do
      it 'should tell if its value is not NaN nor Infinity' do
        node = parser.parse('0.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-0).isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('42.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42).isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('0.0.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-0.0).isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('42.123.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42.123).isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('NaN.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('Infinity.isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-Infinity).isFinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)
      end
    end

    describe 'isInfinite' do
      it 'should tell if its value is Infinity or -Infinity' do
        node = parser.parse('0.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0).isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-42).isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('0.0.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0.0).isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.123.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-42.123).isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('NaN.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('Infinity.isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-Infinity).isInfinite', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)
      end
    end

    describe 'isNaN' do
      it 'should tell if its value is NaN' do
        node = parser.parse('0.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0).isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-42).isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('0.0.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0.0).isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.123.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-42.123).isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('NaN.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('Infinity.isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-Infinity).isNaN', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)
      end
    end

    describe 'isNonZero' do
      it 'should tell if its value is not zero' do
        node = parser.parse('0.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42).isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('0.0.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0.0).isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('42.123.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-42.123).isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('NaN.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('Infinity.isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-Infinity).isNonZero', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)
      end
    end

    describe 'isEven' do
      it 'should tell if its value is even' do
        node = parser.parse('0.isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-0).isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('123.isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-123).isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('124.isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-124).isEven', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)
      end
    end

    describe 'isOdd' do
      it 'should tell if its value is odd' do
        node = parser.parse('0.isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-0).isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('123.isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('(-123).isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('124.isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('(-124).isOdd', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)
      end
    end

    describe 'inv' do
      it 'should bitwise not of its value' do
        node = parser.parse('0.inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(-1)

        node = parser.parse('(-0).inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(-1)

        node = parser.parse('1.inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(-2)

        node = parser.parse('(-1).inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(-124)

        node = parser.parse('(-123).inv', root: :expression)
        expect(node.evaluate(nil)).to be_int(122)
      end
    end
  end

  describe 'methods' do
    describe 'toString' do
      it 'should convert its value to its decimal string representation' do
        node = parser.parse('0.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('0')

        node = parser.parse('(-0).toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('0')

        node = parser.parse('123.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('123')

        node = parser.parse('(-123).toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('-123')

        node = parser.parse('0.0.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('0.0')

        node = parser.parse('(-0.0).toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('-0.0')

        node = parser.parse('2.34.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('2.34')

        node = parser.parse('(-2.34).toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('-2.34')

        node = parser.parse('NaN.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('NaN')

        node = parser.parse('Infinity.toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('Infinity')

        node = parser.parse('(-Infinity).toString()', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('-Infinity')
      end
    end

    describe 'round' do
      it 'should round its value to the nearest mathematical integer' do
        node = parser.parse('0.round()', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).round()', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.round()', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('(-123).round()', root: :expression)
        expect(node.evaluate(nil)).to be_int(-123)

        node = parser.parse('0.0.round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-0.0)

        node = parser.parse('2.34.round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.0)

        node = parser.parse('(-2.34).round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-2.0)

        node = parser.parse('2.9.round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(3.0)

        node = parser.parse('(-2.9).round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-3.0)

        node = parser.parse('NaN.round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)

        node = parser.parse('Infinity.round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)

        node = parser.parse('(-Infinity).round()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-Float::INFINITY)
      end
    end

    describe 'truncate' do
      it 'should round its value to the nearest mathematical integer towards zero' do
        node = parser.parse('0.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('(-0).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_int(0)

        node = parser.parse('123.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_int(123)

        node = parser.parse('(-123).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_int(-123)

        node = parser.parse('0.0.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(0.0)

        node = parser.parse('(-0.0).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-0.0)

        node = parser.parse('2.34.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.0)

        node = parser.parse('(-2.34).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-2.0)

        node = parser.parse('2.9.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(2.0)

        node = parser.parse('(-2.9).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-2.0)

        node = parser.parse('NaN.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)

        node = parser.parse('Infinity.truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::INFINITY)

        node = parser.parse('(-Infinity).truncate()', root: :expression)
        expect(node.evaluate(nil)).to be_float(-Float::INFINITY)
      end
    end
  end
end
