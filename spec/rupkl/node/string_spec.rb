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
          baz = "\(foo) \(bar) \((foo){ 4 })"
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-1].value)
            .to be_evaluated_string(
              'new Dynamic { foo = 1; ["foo"] = 2; 3 } ' \
              'new Dynamic { new Dynamic { foo = 1; ["foo"] = 2; 3 } } ' \
              'new Dynamic { foo = 1; ["foo"] = 2; 3; 4 }'
            )
        end

        node = parser.parse(<<~'PKL'.chomp, root: :object)
          { foo = 0; bar = 1; baz = "\(this)" }
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-1].value)
            .to be_evaluated_string(
              'new Dynamic { foo = 0; bar = 1; baz = "new Dynamic { foo = 0; bar = 1; baz = ? }" }'
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
        # equality
        node = parser.parse('"foo"=="foo"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"=="bar"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"==1', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"==1.0', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"==true', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"==new Dynamic{}', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"==new Mapping{}', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        # inequality
        node = parser.parse('"foo"!="foo"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(false)

        node = parser.parse('"foo"!="bar"', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=1', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=1.0', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=true', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=new Dynamic{}', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=new Mapping{}', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        node = parser.parse('"foo"!=new Listing{}', root: :expression)
        expect(node.evaluate(nil)).to be_boolean(true)

        # add
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
        ['+'].each do |op|
          node = parser.parse("\"foo\"#{op}true", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

          node = parser.parse("\"foo\"#{op}1", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

          node = parser.parse("\"foo\"#{op}1.0", root: :expression)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'length' do
      it 'should return the number of characters in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s1 = "abcdefg"
          s2 = "あいうえお"
          a = "".length
          b = "   ".length
          c = "\t\n\r".length
          d = s1.length
          e = s2.length
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(3)
          expect(c.value).to be_int(3)
          expect(d.value).to be_int(7)
          expect(e.value).to be_int(5)
        end
      end
    end

    describe 'lastIndex' do
      it 'should return the index of the last character in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s1 = "abcdefg"
          s2 = "あいうえお"
          a = "".lastIndex
          b = "   ".lastIndex
          c = "\t\n\r".lastIndex
          d = s1.lastIndex
          e = s2.lastIndex
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_int(-1)
          expect(b.value).to be_int(2)
          expect(c.value).to be_int(2)
          expect(d.value).to be_int(6)
          expect(e.value).to be_int(4)
        end
      end
    end

    describe 'isEmpty' do
      it 'should tell whether this string is empty' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = "".isEmpty
          b = "   ".isEmpty
          c = "\t\n\r".isEmpty
          d = "　".isEmpty
          e = s.isEmpty
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(false)
          expect(c.value).to be_boolean(false)
          expect(d.value).to be_boolean(false)
          expect(e.value).to be_boolean(false)
        end
      end
    end

    describe 'isBlank' do
      it 'should tell if all characters in this string have Unicode property "White_Space"' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = "".isBlank
          b = "   ".isBlank
          c = "\t\n\r".isBlank
          d = "　".isBlank
          e = s.isBlank
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(false)
        end
      end
    end

    describe 'md5' do
      it 'should return the MD5 hash of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".md5
          b = "The quick brown fox jumps over the lazy dog".md5
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_evaluated_string('d41d8cd98f00b204e9800998ecf8427e')
          expect(b.value).to be_evaluated_string('9e107d9d372bb6826bd81d3542a419d6')
        end
      end
    end

    describe 'sha1' do
      it 'should return the SHA-1 hash of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".sha1
          b = "The quick brown fox jumps over the lazy dog".sha1
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_evaluated_string('da39a3ee5e6b4b0d3255bfef95601890afd80709')
          expect(b.value).to be_evaluated_string('2fd4e1c67a2d28fced849ee1bb76e7391b93eb12')
        end
      end
    end

    describe 'sha256' do
      it 'should return the SHA-256 hash of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".sha256
          b = "The quick brown fox jumps over the lazy dog".sha256
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_evaluated_string('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')
          expect(b.value).to be_evaluated_string('d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592')
        end
      end
    end

    describe 'sha256Int' do
      it 'should return the first 64 bits of the SHA-256 hash of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".sha256Int
          b = "The quick brown fox jumps over the lazy dog".sha256Int
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_int(1449310910991872227)
          expect(b.value).to be_int(-7745954930992895785)
        end
      end
    end
  end
end
