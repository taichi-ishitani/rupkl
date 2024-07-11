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

    describe 'base64' do
      it 'should return the Base64 encoding of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".base64
          b = "The quick brown fox jumps over the lazy dog".base64
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZw==')
        end
      end
    end

    describe 'base64Decoded' do
      it 'should be the inverse of base64' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          a = "".base64Decoded
          b = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZw==".base64Decoded
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('The quick brown fox jumps over the lazy dog')
        end
      end

      context 'when this string includes illegal bsae64 character' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            a = "~~~".base64Decoded
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'illegal base64: "~~~"'
        end
      end
    end

    describe 'getOrNull' do
      it 'should return the character at the index' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = s.getOrNull(0)
          b = s.getOrNull(3)
          c = s.getOrNull(6)
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string('a')
          expect(b.value).to be_evaluated_string('d')
          expect(c.value).to be_evaluated_string('g')
        end
      end

      context 'when the given index is out of ragne' do
        it 'should return a null value' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "abcdefg"
            a = s.getOrNull(-1)
            b = s.getOrNull(7)
          PKL
          node.evaluate(nil).properties[-2..].then do |(a, b)|
            expect(a.value).to be_null
            expect(b.value).to be_null
          end
        end
      end
    end

    describe 'substring' do
      it 'should the substring specified by the given range' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = s.substring(2, 2)
          b = s.substring(2, 3)
          c = s.substring(2, 4)
          d = s.substring(0, 7)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('c')
          expect(c.value).to be_evaluated_string('cd')
          expect(d.value).to be_evaluated_string('abcdefg')
        end
      end

      context 'when the given range is outside of the range of this string' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "abcdefg"
            a = s.substring(-1, 4)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index -1 is out of range 0..7: "abcdefg"'

          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "abcdefg"
            a = s.substring(1, 8)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index 8 is out of range 1..7: "abcdefg"'

          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "abcdefg"
            a = s.substring(3, 2)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index 2 is out of range 3..7: "abcdefg"'
        end
      end
    end

    describe 'substringOrNull' do
      it 'should the substring specified by the given range' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = s.substringOrNull(2, 2)
          b = s.substringOrNull(2, 3)
          c = s.substringOrNull(2, 4)
          d = s.substringOrNull(0, 7)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('c')
          expect(c.value).to be_evaluated_string('cd')
          expect(d.value).to be_evaluated_string('abcdefg')
        end
      end

      context 'when the given range is outside of the range of this string' do
        it 'should return a null value' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "abcdefg"
            a = s.substringOrNull(-1, 4)
            b = s.substringOrNull(1, 8)
            c = s.substringOrNull(3, 2)
          PKL
          node.evaluate(nil).properties[-3..].then do |(a, b, c)|
            expect(a.value).to be_null
            expect(b.value).to be_null
            expect(c.value).to be_null
          end
        end
      end
    end

    describe 'repeat' do
      it 'should concatenates count copies of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          a = s0.repeat(0)
          b = s0.repeat(1)
          c = s0.repeat(5)
          d = s1.repeat(0)
          e = s1.repeat(1)
          f = s1.repeat(5)
        PKL
        node.evaluate(nil).properties[-6..].then do |(a, b, c, d, e, f)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('abcdefg')
          expect(c.value).to be_evaluated_string('abcdefgabcdefgabcdefgabcdefgabcdefg')
          expect(d.value).to be_evaluated_string('')
          expect(e.value).to be_evaluated_string('')
          expect(f.value).to be_evaluated_string('')
        end
      end

      context 'when the given value is negative' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            a = s0.repeat(-1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a positive number, but got \'-1\''
        end
      end
    end

    describe 'contains' do
      it 'should tell whether this string contains pattern' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = "cde"
          s2 = ""
          a = s0.contains(s0)
          b = s0.contains(s1)
          c = s0.contains(s2)
          d = s1.contains(s0)
          e = s1.contains(s1)
          f = s1.contains(s2)
          g = s2.contains(s0)
          h = s2.contains(s1)
          i = s2.contains(s2)
        PKL
        node.evaluate(nil).properties[-9..].then do |(a, b, c, d, e, f, g, h, i)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(false)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(false)
          expect(h.value).to be_boolean(false)
          expect(i.value).to be_boolean(true)
        end
      end
    end

    describe 'startsWith' do
      it 'should tell whether this string starts with pattern' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          s2 = "abc"
          s3 = "abx"
          a = s0.startsWith(s0)
          b = s0.startsWith(s1)
          c = s0.startsWith(s2)
          d = s0.startsWith(s3)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(false)
        end
      end
    end

    describe 'endsWith' do
      it 'should tell whether this string ends with pattern' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          s2 = "efg"
          s3 = "efx"
          a = s0.endsWith(s0)
          b = s0.endsWith(s1)
          c = s0.endsWith(s2)
          d = s0.endsWith(s3)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(false)
        end
      end
    end

    describe 'indexOf' do
      it 'should return the index of the first occurrence of pattern in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          s2 = "abc"
          s3 = "cde"
          a = s0.indexOf(s0)
          b = s0.indexOf(s1)
          c = s0.indexOf(s2)
          d = s0.indexOf(s3)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(0)
          expect(c.value).to be_int(0)
          expect(d.value).to be_int(2)
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            s1 = "cdx"
            a = s0.indexOf(s1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error '"cdx" does not occur in "abcdefg"'
        end
      end
    end

    describe 'indexOfOrNull' do
      it 'should return the index of the first occurrence of pattern in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          s2 = "abc"
          s3 = "cde"
          a = s0.indexOfOrNull(s0)
          b = s0.indexOfOrNull(s1)
          c = s0.indexOfOrNull(s2)
          d = s0.indexOfOrNull(s3)
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(0)
          expect(c.value).to be_int(0)
          expect(d.value).to be_int(2)
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should return a null value' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            s1 = "cdx"
            a = s0.indexOfOrNull(s1)
          PKL
          node.evaluate(nil).properties[-1].then do |a|
            expect(a.value).to be_null
          end
        end
      end
    end

    describe 'lastIndexOf' do
      it 'should return the index of the last occurrence of pattern in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abxabyabz"
          s1 = ""
          s2 = "ab"
          a = s0.lastIndexOf(s0)
          b = s0.lastIndexOf(s1)
          c = s0.lastIndexOf(s2)
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(9)
          expect(c.value).to be_int(6)
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abxabyabz"
            s1 = "cdx"
            a = s0.lastIndexOf(s1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error '"cdx" does not occur in "abxabyabz"'
        end
      end
    end

    describe 'lastIndexOfOrNull' do
      it 'should return the index of the last occurrence of pattern in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abxabyabz"
          s1 = ""
          s2 = "ab"
          a = s0.lastIndexOfOrNull(s0)
          b = s0.lastIndexOfOrNull(s1)
          c = s0.lastIndexOfOrNull(s2)
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(9)
          expect(c.value).to be_int(6)
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abxabyabz"
            s1 = "cdx"
            a = s0.lastIndexOfOrNull(s1)
          PKL
          node.evaluate(nil).properties[-1].then do |a|
            expect(a.value).to be_null
          end
        end
      end
    end

    describe 'take' do
      it 'should returns the first n characters of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          a = s0.take(0)
          b = s0.take(3)
          c = s0.take(42)
          d = s1.take(0)
          e = s1.take(3)
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('abc')
          expect(c.value).to be_evaluated_string('abcdefg')
          expect(d.value).to be_evaluated_string('')
          expect(e.value).to be_evaluated_string('')
        end
      end

      context 'when the given value is negative' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            a = s0.take(-1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a positive number, but got \'-1\''
        end
      end
    end

    describe 'takeLast' do
      it 'should returns the last n characters of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          a = s0.takeLast(0)
          b = s0.takeLast(3)
          c = s0.takeLast(42)
          d = s1.takeLast(0)
          e = s1.takeLast(3)
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('efg')
          expect(c.value).to be_evaluated_string('abcdefg')
          expect(d.value).to be_evaluated_string('')
          expect(e.value).to be_evaluated_string('')
        end
      end

      context 'when the given value is negative' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            a = s0.takeLast(-1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a positive number, but got \'-1\''
        end
      end
    end

    describe 'drop' do
      it 'should remove the first n characters of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          a = s0.drop(0)
          b = s0.drop(3)
          c = s0.drop(42)
          d = s1.drop(0)
          e = s1.drop(3)
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_evaluated_string('abcdefg')
          expect(b.value).to be_evaluated_string('defg')
          expect(c.value).to be_evaluated_string('')
          expect(d.value).to be_evaluated_string('')
          expect(e.value).to be_evaluated_string('')
        end
      end

      context 'when the given value is negative' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            a = s0.drop(-1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a positive number, but got \'-1\''
        end
      end
    end

    describe 'dropLast' do
      it 'should remove the last n characters of this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "abcdefg"
          s1 = ""
          a = s0.dropLast(0)
          b = s0.dropLast(3)
          c = s0.dropLast(42)
          d = s1.dropLast(0)
          e = s1.dropLast(3)
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to be_evaluated_string('abcdefg')
          expect(b.value).to be_evaluated_string('abcd')
          expect(c.value).to be_evaluated_string('')
          expect(d.value).to be_evaluated_string('')
          expect(e.value).to be_evaluated_string('')
        end
      end

      context 'when the given value is negative' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "abcdefg"
            a = s0.dropLast(-1)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a positive number, but got \'-1\''
        end
      end
    end

    describe 'replaceFirst' do
      it 'should replace the first occurrence of pattern in this string with replacement' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "aabbccaabbcc"
          s1 = "aabb..aabbcc"
          a = s0.replaceFirst("aa", "xx")
          b = s1.replaceFirst(".", "x")
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_evaluated_string('xxbbccaabbcc')
          expect(b.value).to be_evaluated_string('aabbx.aabbcc')
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should return this string unchanged' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "aabbccaabbcc"
            s1 = "aabb..aabbcc"
            a = s0.replaceFirst("xx", "yy")
            b = s1.replaceFirst("-", "x")
          PKL
          node.evaluate(nil).properties[-2..].then do |(a, b)|
            expect(a.value).to be_evaluated_string('aabbccaabbcc')
            expect(b.value).to be_evaluated_string('aabb..aabbcc')
          end
        end
      end
    end

    describe 'replaceLast' do
      it 'should replace the last occurrence of pattern in this string with replacement' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "aabbccaabbcc"
          s1 = "aabb..aabbcc"
          a = s0.replaceLast("aa", "xx")
          b = s1.replaceLast(".", "x")
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_evaluated_string('aabbccxxbbcc')
          expect(b.value).to be_evaluated_string('aabb.xaabbcc')
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should return this string unchanged' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "aabbccaabbcc"
            s1 = "aabb..aabbcc"
            a = s0.replaceLast("xx", "yy")
            b = s1.replaceLast("-", "x")
          PKL
          node.evaluate(nil).properties[-2..].then do |(a, b)|
            expect(a.value).to be_evaluated_string('aabbccaabbcc')
            expect(b.value).to be_evaluated_string('aabb..aabbcc')
          end
        end
      end
    end

    describe 'replaceAll' do
      it 'should replace all occurrences of pattern in this string with replacement' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "aabbccaabbcc"
          s1 = "aabb..aabbcc"
          a = s0.replaceAll("aa", "xx")
          b = s1.replaceAll(".", "x")
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_evaluated_string('xxbbccxxbbcc')
          expect(b.value).to be_evaluated_string('aabbxxaabbcc')
        end
      end

      context 'when the pattern does not occur in this string' do
        it 'should return this string unchanged' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s0 = "aabbccaabbcc"
            s1 = "aabb..aabbcc"
            a = s0.replaceAll("xx", "yy")
            b = s1.replaceAll("-", "x")
          PKL
          node.evaluate(nil).properties[-2..].then do |(a, b)|
            expect(a.value).to be_evaluated_string('aabbccaabbcc')
            expect(b.value).to be_evaluated_string('aabb..aabbcc')
          end
        end
      end
    end

    describe 'replaceRange' do
      it 'should replace the characters between start and exclusiveEnd with replacement' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = "aabbccaabbcc"
          a = s0.replaceRange(5, 10, "XXX")
          b = s0.replaceRange(10, 12, "extend beyond string end")
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_evaluated_string('aabbcXXXcc')
          expect(b.value).to be_evaluated_string('aabbccaabbextend beyond string end')
        end
      end

      context 'when the given range is outside of the range of this string' do
        it 'should raise EvaluationError' do
          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "aabbccaabbcc"
            a = s.replaceRange(0, 100, "_")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index 100 is out of range 0..12: "aabbccaabbcc"'

          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "aabbccaabbcc"
            a = s.replaceRange(-10, 5, "_")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index -10 is out of range 0..12: "aabbccaabbcc"'

          node = parser.parse(<<~'PKL', root: :pkl_module)
            s = "aabbccaabbcc"
            a = s.replaceRange(3, 2, "_")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'index 2 is out of range 3..12: "aabbccaabbcc"'
        end
      end
    end

    describe 'toUpperCase' do
      it 'should perform a locale-independent character-by-character conversion of this string to uppercase' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcABCabc"
          a = s.toUpperCase()
        PKL
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value).to be_evaluated_string('ABCABCABC')
        end
      end
    end

    describe 'toLowerCase' do
      it 'should performs  locale-independent character-by-character conversion of this string to lowercase' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcABCabc"
          a = s.toLowerCase()
        PKL
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value).to be_evaluated_string('abcabcabc')
        end
      end
    end

    describe 'reverse' do
      it 'should reverse the order of characters in this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s = "abcdefg"
          a = s.reverse()
        PKL
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value).to be_evaluated_string('gfedcba')
        end
      end
    end

    describe 'trim' do
      it 'should remove any leading and trailing characters with Unicode property "White_Space" from this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = " \t abcdefg \t \n"
          s1 = " \t  \t \n"
          s2 = "　あいう　"
          a = s0.trim()
          b = s1.trim()
          c = s2.trim()
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string('abcdefg')
          expect(b.value).to be_evaluated_string('')
          expect(c.value).to be_evaluated_string('あいう')
        end
      end
    end

    describe 'trimStart' do
      it 'should remove any leading characters with Unicode property "White_Space" from this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = " \t abcdefg \t \n"
          s1 = " \t  \t \n"
          s2 = "　あいう　"
          a = s0.trimStart()
          b = s1.trimStart()
          c = s2.trimStart()
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string("abcdefg \t \n")
          expect(b.value).to be_evaluated_string('')
          expect(c.value).to be_evaluated_string('あいう　')
        end
      end
    end

    describe 'trimEnd' do
      it 'should remove any trailing characters with Unicode property "White_Space" from this string' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          s0 = " \t abcdefg \t \n"
          s1 = " \t  \t \n"
          s2 = "　あいう　"
          a = s0.trimEnd()
          b = s1.trimEnd()
          c = s2.trimEnd()
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string(" \t abcdefg")
          expect(b.value).to be_evaluated_string('')
          expect(c.value).to be_evaluated_string('　あいう')
        end
      end
    end
  end
end
