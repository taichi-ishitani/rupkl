# frozen_string_literal: true

RSpec.describe RuPkl::Node::Null do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#to_ruby' do
    it 'should return nil' do
      node = parser.parse('null', root: :expression)
      expect(node.to_ruby(nil)).to be_nil
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a stirng representing its value' do
      node = parser.parse('null', root: :expression)
      expect(node.to_string(nil)).to eq 'null'
      expect(node.to_pkl_string(nil)).to eq 'null'
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parser.parse('null[0]', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Null type'
    end
  end

  describe 'unary operation' do
    specify 'unary operations are not defined' do
      node = parser.parse('!null', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!@\' is not defined for Null type'

      node = parser.parse('-null', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-@\' is not defined for Null type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      it 'should execute the given operation' do
        # equality
        node = parser.parse('null == null', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('null == 1', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('1 == null', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        # inequality
        node = parser.parse('null != null', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('null != 1', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('1 != null', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)
      end
    end

    context 'when undefined is given' do
      it 'should raise EvaluationError' do
        [
          '||', '&&', '<', '>', '<=', '>=',
          '+', '-', '*', '/', '~/', '%', '**'
        ].each do |op|
          node = parser.parse("null #{op} 123", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Null type"
        end
      end
    end
  end
end
