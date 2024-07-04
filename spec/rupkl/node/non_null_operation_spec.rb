# frozen_string_literal: true

RSpec.describe RuPkl::Node::NonNullOperation do
  let(:parser) do
    RuPkl::Parser.new
  end

  context 'when the given operand is a non null value' do
    it 'should return the given operand' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        a = 123
        b = 123!!
        c = a!!
      PKL
      node.evaluate(nil).properties[-2..].then do |(b, c)|
        expect(b.value).to be_int(123)
        expect(c.value).to be_int(123)
      end
    end
  end

  context 'when the given operand is a null value' do
    it 'should raise EvaluationError' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        a = null!!
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'expected a non-null value but got \'null\''

      node = parser.parse(<<~'PKL', root: :pkl_module)
        a = null
        b = a!!
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'expected a non-null value but got \'null\''
    end
  end
end
