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
end
