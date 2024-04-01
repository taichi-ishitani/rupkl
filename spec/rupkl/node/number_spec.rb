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
      node = parser.parse(int_value.to_s, root: :integer_literal)
      expect(node.evaluate(nil)).to be node

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.evaluate(nil)).to be node
    end
  end

  describe '#to_ruby' do
    it 'should return its value' do
      node = parser.parse(int_value.to_s, root: :integer_literal)
      expect(node.to_ruby(nil)).to eq int_value

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.to_ruby(nil)).to eq float_value
    end
  end

  describe '#to_pkl_string' do
    it 'should return a Pkl string representing its value' do
      node = parser.parse(int_value.to_s, root: :integer_literal)
      expect(node.to_pkl_string(nil)).to eq int_value.to_s

      node = parser.parse(float_value.to_s, root: :float_literal)
      expect(node.to_pkl_string(nil)).to eq float_value.to_s
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parser.parse("#{int_value}[0]", root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Integer type'

      node = parser.parse("#{float_value}[0]", root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Float type'
    end
  end

  describe 'unary operation' do
    context 'when the given operator is defined' do
      it 'should execute the given operation' do
        node = parser.parse('-1', root: :expression)
        expect(node.evaluate(nil)).to be_integer(-1)

        node = parser.parse('-1.0', root: :expression)
        expect(node.evaluate(nil)).to be_float(-1.0)
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluatedError' do
        node = parser.parse('!1', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!\' is not defined for Integer type'

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

        ['2==3', '2.0==3.0', '2==3.0', '2.0==3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # inequality
        ['2!=3', '2.0!=3.0', '2!=3.0', '2.0!=3'].each do |pkl|
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

        # integer division
        ['4~/3', '4.0~/3.0', '4~/3.0', '4.0~/3'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_integer(1)
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
          .to raise_evaluation_error 'operator \'||\' is not defined for Integer type'

        node = parser.parse('1.0||true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for Float type'

        node = parser.parse('1&&true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Integer type'

        node = parser.parse('1.0&&true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Float type'
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        [
          '==', '!=', '>', '<', '>=', '<=',
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
end
