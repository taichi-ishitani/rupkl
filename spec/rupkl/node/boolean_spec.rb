# frozen_string_literal: true

RSpec.describe RuPkl::Node::Boolean do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parser.parse('true', root: :boolean_literal)
      expect(node.evaluate(nil)).to be node

      node = parser.parse('false', root: :boolean_literal)
      expect(node.evaluate(nil)).to be node
    end
  end

  describe '#to_ruby' do
    it 'should return its value' do
      node = parser.parse('true', root: :boolean_literal)
      expect(node.to_ruby(nil)).to be true

      node = parser.parse('false', root: :boolean_literal)
      expect(node.to_ruby(nil)).to be false
    end
  end
end
