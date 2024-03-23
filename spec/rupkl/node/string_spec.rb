# frozen_string_literal: true

RSpec.describe RuPkl::Node::String do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    context 'when portions are given' do
      it 'should evaluate portions and return a node contaings evaluation result' do
        node = parser.parse('""', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('')

        node = parser.parse('"Hellow, World!"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('Hellow, World!')

        node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
          """
          """
        PKL
        expect(node.evaluate(nil)).to be_evaluated_string('')

        node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
          """
          Although the Dodo is extinct,
          the species will be remembered.
          """
        PKL
        expect(node.evaluate(nil)).to be_evaluated_string(<<~'OUT'.chomp)
          Although the Dodo is extinct,
          the species will be remembered.
        OUT
      end
    end
  end

  describe 'to_ruby' do
    context 'when portions are given' do
      it 'should evaluate portions and return the evaluation result' do
        node = parser.parse('""', root: :string_literal)
        expect(node.to_ruby(nil)).to eq ''

        node = parser.parse('"Hellow, World!"', root: :string_literal)
        expect(node.to_ruby(nil)).to eq 'Hellow, World!'

        node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
          """
          """
        PKL
        expect(node.to_ruby(nil)).to eq ''

        node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
          """
          Although the Dodo is extinct,
          the species will be remembered.
          """
        PKL
        expect(node.to_ruby(nil)).to eq <<~'OUT'.chomp
          Although the Dodo is extinct,
          the species will be remembered.
        OUT
      end
    end
  end

  describe '#u_op' do
    it 'should raise EvaluationError' do
      node = parser.parse('!"foo"', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for String type'

      node = parser.parse('-"foo"', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for String type'
    end
  end

  describe '#b_op' do
    context 'when defined operator and valid operand are given' do
      it 'should execlute the given operation' do
        node = parser.parse('"foo"=="foo"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"=="bar"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-', '*', '/', '~/', '%', '**',
          '&&', '||'
        ].each do |op|
          node = parser.parse("\"foo\"#{op}\"bar\"", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for String type"
        end
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        ['==', '!='].each do |op|
          node = parser.parse("\"foo\"#{op}true", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

          node = parser.parse("\"foo\"#{op}1", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Integer is given for operator '#{op}'"

          node = parser.parse("\"foo\"#{op}1.0", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"
        end
      end
    end
  end
end
