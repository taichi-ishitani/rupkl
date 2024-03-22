# frozen_string_literal: true

RSpec.describe RuPkl::Node::BinaryOperation do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should execute its operation' do
      node = parser.parse('1+2', root: :expression)

      expect(node.l_operand)
        .to receive(:b_op).with(:+, be(node.r_operand))
        .and_call_original
      expect(node.evaluate(nil)).to be_integer(3)
    end
  end

  describe '#to_ruby' do
    it 'should return the result of its operation' do
      node = parser.parse('1+2', root: :expression)
      expect(node.to_ruby(nil)).to eq 3
    end
  end
end
