# frozen_string_literal: true

RSpec.describe RuPkl::Node::IfExpression do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string.chomp, root: :expression)
  end

  describe '#evaluate' do
    context 'when the given condition is evaluated to true' do
      it 'should evaluate the \'if\' expression' do
        node = parse(<<~PKL)
          if (true) 1 else 2
        PKL
        expect(node.evaluate(nil)).to be_int(1)

        node = parse(<<~PKL)
          if (true) 3 else if (true) 4 else 5
        PKL
        expect(node.evaluate(nil)).to be_int(3)

        node = parse(<<~PKL)
          if (true) 3 else if (false) 4 else 5
        PKL
        expect(node.evaluate(nil)).to be_int(3)
      end
    end

    context 'when the given condition is evaluated to false' do
      it 'should evaluate the \'else\' expression' do
        node = parse(<<~PKL)
          if (false) 1 else 2
        PKL
        expect(node.evaluate(nil)).to be_int(2)

        node = parse(<<~PKL)
          if (false) 3 else if (true) 4 else 5
        PKL
        expect(node.evaluate(nil)).to be_int(4)

        node = parse(<<~PKL)
          if (false) 3 else if (false) 4 else 5
        PKL
        expect(node.evaluate(nil)).to be_int(5)
      end
    end

    context 'when tht given condition is evaluated to a non boolean value' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          if (0) 1 else 2
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'expected type \'Boolean\', but got type \'Int\''

        node = parse(<<~'PKL')
          if ("") 1 else 2
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'expected type \'Boolean\', but got type \'String\''

        node = parse(<<~'PKL')
          if (null) 1 else 2
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'expected type \'Boolean\', but got type \'Null\''
      end
    end
  end
end
