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

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing its value' do
      node = parser.parse('true', root: :boolean_literal)
      expect(node.to_string(nil)).to eq 'true'
      expect(node.to_pkl_string(nil)).to eq 'true'

      node = parser.parse('false', root: :boolean_literal)
      expect(node.to_string(nil)).to eq 'false'
      expect(node.to_pkl_string(nil)).to eq 'false'
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parser.parse('true[0]', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Boolean type'

      node = parser.parse('false[0]', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Boolean type'
    end
  end

  describe 'unary operation' do
    context 'when the given operator is defined' do
      it 'should execute the given operation' do
        node = parser.parse('!true', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('!false', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluatedError' do
        node = parser.parse('-true', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'-\' is not defined for Boolean type'

        node = parser.parse('-false', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'-\' is not defined for Boolean type'
      end
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      it 'should execlute the given operation' do
        # equality
        ['true==true', 'false==false'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        [
          'true==false', 'false==true',
          'true==1', 'true==1.0', 'true=="foo"', 'true==new Dynamic{}', 'true==new Mapping{}',
          'true==1', 'false==1.0', 'false=="foo"', 'false==new Dynamic{}', 'false==new Mapping{}'
        ].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # inequality
        [
          'true!=false', 'false!=true',
          'true!=1', 'true!=1.0', 'true!="foo"',
          'true!=new Dynamic{}', 'true!=new Mapping{}', 'true!=new Listing{}',
          'true!=1', 'false!=1.0', 'false!="foo"',
          'false!=new Dynamic{}', 'false!=new Mapping{}', 'false!=new Listing{}'
        ].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['true!=true', 'false!=false'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # logical conjunction
        ['true&&true'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['true&&false', 'false&&true', 'false&&false'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end

        # logical disjunction
        ['true||true', 'true||false', 'false||true'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(true)
        end

        ['false||false'].each do |pkl|
          node = parser.parse(pkl, root: :expression)
          expect(node.evaluate(nil)).to be_boolean(false)
        end
      end
    end

    specify '&& and || operators uses short-circuit evaluation' do
      node = parser.parse('true||"foo"', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(true)

      node = parser.parse('true||1', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(true)

      node = parser.parse('true||1.0', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(true)

      node = parser.parse('false&&"foo"', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(false)

      node = parser.parse('false&&1', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(false)

      node = parser.parse('false&&1.0', root: :expression)
      expect(node.r_operand).not_to receive(:evaluate)
      expect(node.evaluate(nil)).to be_boolean(false)
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-', '*', '/', '~/', '%', '**'
        ].each do |op|
          node = parser.parse("true#{op}false", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Boolean type"

          node = parser.parse("false#{op}true", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Boolean type"
        end
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        ['&&', '||'].each do |op|
          if op != '||'
            node = parser.parse("true#{op}\"foo\"", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

            node = parser.parse("true#{op}1", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

            node = parser.parse("true#{op}1.0", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"
          end

          if op != '&&'
            node = parser.parse("false#{op}\"foo\"", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

            node = parser.parse("false#{op}1", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

            node = parser.parse("false#{op}1.0", root: :expression)
            expect { node.evaluate(nil) }
              .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"
          end
        end
      end
    end
  end
end
