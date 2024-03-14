# frozen_string_literal: true

RSpec.describe RuPkl::Node::Integer do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:value) do
    rand(0..1000)
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parser.parse(value.to_s, root: :integer_literal)
      expect(node.evaluate(nil)).to be node
    end
  end

  describe '#to_ruby' do
    it 'should return its value' do
      node = parser.parse(value.to_s, root: :integer_literal)
      expect(node.to_ruby(nil)).to eq value
    end
  end
end
