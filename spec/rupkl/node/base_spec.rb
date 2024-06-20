# frozen_string_literal: true

RSpec.describe RuPkl::Node::Base do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'properties' do
    describe 'NaN' do
      it 'should return the NaN value' do
        node = parser.parse('NaN', root: :expression)
        expect(node.evaluate(nil)).to be_float(Float::NAN)
      end
    end

    describe 'Infinity' do
      it 'should return the Infinity value' do
        node = parser.parse('Infinity', root: :expression)
         expect(node.evaluate(nil)).to be_float(Float::INFINITY)
      end
    end
  end
end
