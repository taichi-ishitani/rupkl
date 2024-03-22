# frozen_string_literal: true

RSpec.describe RuPkl::Node::UnaryOperation do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should execute its operation' do
      node = parser.parse('-1', root: :expression)

      expect(node.operand)
        .to receive(:u_op).with(:-)
        .and_call_original
      expect(node.evaluate(nil)).to be_integer(-1)
    end
  end

  describe '#to_ruby' do
    it 'should return the result of its operation' do
      node = parser.parse('-1', root: :expression)
      expect(node.to_ruby(nil)).to eq -1
    end
  end
end
