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

        node = parser.parse('"\(42)"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('42')

        node = parser.parse('"\(40 + 2)"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('42')

        node = parser.parse('"\(1.23)"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('1.23')

        node = parser.parse('"\("Pigion")"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('Pigion')

        node = parser.parse('"\(false)"', root: :string_literal)
        expect(node.evaluate(nil)).to be_evaluated_string('false')

        node = parser.parse(<<~'PKL', root: :pkl_module)
          str1 = "How"
          str2 = "you"
          str3 = "\(str1) are \(str2) today? Are \(str2) hungry?"
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-1].value).to be_evaluated_string('How are you today? Are you hungry?')
        end

        node = parser.parse(<<~'PKL', root: :pkl_module)
          str1 = "How"
          str2 = "you"
          str3 = "this"
          str4 = "Can \(str2 + " nest \(str3)") for me?"
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-1].value).to be_evaluated_string('Can you nest this for me?')
        end

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo { foo = 1 ["foo"] = 2 1 + 2 }
          bar { foo }
          baz = "\(foo) \(bar)"
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-1].value)
            .to be_evaluated_string(
              'new Dynamic { foo = 1; ["foo"] = 2; 3 } ' \
              'new Dynamic { { foo = 1; ["foo"] = 2; 3 } }'
            )
        end
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

  describe '#to_string' do
    it 'should return a string representing its value' do
      node = parser.parse('""', root: :string_literal)
      expect(node.to_string(nil)).to eq ''

      node = parser.parse('"Hellow, World!"', root: :string_literal)
      expect(node.to_string(nil)).to eq 'Hellow, World!'

      node = parser.parse('"\\\\\\"\\\\("', root: :string_literal)
      expect(node.to_string(nil)).to eq '\"\('

      node = parser.parse('"\t\r\n"', root: :string_literal)
      expect(node.to_string(nil)).to eq "\t\r\n"

      node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
        """
        """
      PKL
      expect(node.to_string(nil)).to eq ''

      node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
        """
        Although the Dodo is extinct,
        the species will be remembered.
        """
      PKL
      expect(node.to_string(nil))
        .to eq "Although the Dodo is extinct,\nthe species will be remembered."
    end
  end

  describe '#to_pkl_string' do
    it 'should return a Pkl string representing its value' do
      node = parser.parse('""', root: :string_literal)
      expect(node.to_pkl_string(nil)).to eq '""'

      node = parser.parse('"Hellow, World!"', root: :string_literal)
      expect(node.to_pkl_string(nil)).to eq '"Hellow, World!"'

      node = parser.parse('"\\\\\\"\\\\("', root: :string_literal)
      expect(node.to_pkl_string(nil)).to eq '"\\\\\\"\\\\("'

      node = parser.parse('"\t\r\n"', root: :string_literal)
      expect(node.to_pkl_string(nil)).to eq '"\t\r\n"'

      node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
        """
        """
      PKL
      expect(node.to_pkl_string(nil)).to eq '""'

      node = parser.parse(<<~'PKL'.chomp, root: :string_literal)
        """
        Although the Dodo is extinct,
        the species will be remembered.
        """
      PKL
      expect(node.to_pkl_string(nil))
        .to eq '"Although the Dodo is extinct,\nthe species will be remembered."'
    end
  end

  describe 'subscript operation' do
    it 'returns the specified character' do
      node = parser.parse('"foo"[0]', root: :expression)
      expect(node.evaluate(nil)).to be_evaluated_string('f')

      node = parser.parse('"foo"[1]', root: :expression)
      expect(node.evaluate(nil)).to be_evaluated_string('o')

      node = parser.parse('"foo"[2]', root: :expression)
      expect(node.evaluate(nil)).to be_evaluated_string('o')
    end

    context 'when the given index is not Integer type' do
      it 'should raise EvaluationError' do
        node = parser.parse('"foo"[true]', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid key operand type Boolean is given for operator '[]'"

        node = parser.parse('"foo"[0.0]', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid key operand type Float is given for operator '[]'"

        node = parser.parse('"foo"["bar"]', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid key operand type String is given for operator '[]'"
      end
    end

    context 'when the given index is out of range' do
      it 'should raise EvaluationError' do
        node = parser.parse('"foo"[-1]', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'-1\''

        node = parser.parse('"foo"[3]', root: :expression)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'3\''
      end
    end
  end

  describe 'unary operation' do
    specify 'unary operations are not defiend' do
      node = parser.parse('!"foo"', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for String type'

      node = parser.parse('-"foo"', root: :expression)
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for String type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      it 'should execlute the given operation' do
        node = parser.parse('"foo"=="foo"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"=="bar"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"+"bar"', root: :expression)
        expect(node.evaluate(nil)).to be_evaluated_string('foobar')
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '-', '*', '/', '~/', '%', '**',
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
