# frozen_string_literal: true

RSpec.describe RuPkl::Node::BinaryOperation do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should execute its operation' do
      node = parser.parse('1+2', root: :expression)
      expect(node.evaluate(nil)).to be_integer(3)
    end

    context 'when the given LHS operand supports no binary operations' do
      it 'should raise EvaluationError' do
        [
          '||', '&&', '==', '!=', '<', '>', '<=', '>=',
          '+', '-', '*', '/', '~/', '%', '**'
        ].each do |op|
          node = parser.parse(<<~PKL, root: :pkl_module)
            foo { bar = 1 }
            baz = foo #{op} 1
          PKL

          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for PklObject type"
        end
      end
    end
  end

  describe '#to_ruby' do
    it 'should return the result of its operation' do
      node = parser.parse('1+2', root: :expression)
      expect(node.to_ruby(nil)).to eq 3
    end
  end
end
