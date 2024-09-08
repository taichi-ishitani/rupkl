# frozen_string_literal: true

RSpec.describe RuPkl::Node::Regex do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_string) do
    <<~'PKL'
      r0 = Regex("")
      r1 = Regex(#"(?i)abc"#)
      r2 = Regex(#"a(\s*)b(\s*)c"#)
      r3 = Regex(#"a(?:\s*)b\(c\)"#)
    PKL
  end

  describe 'Regex method' do
    it 'should create a Regex object' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(r0, r1, r2, r3)|
        expect(r0.value).to be_regex(//)
        expect(r1.value).to be_regex(/(?i)abc/)
        expect(r2.value).to be_regex(/a(\s*)b(\s*)c/)
        expect(r3.value).to be_regex(/a(?:\s*)b\(c\)/)
      end
    end
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(r0, r1, r2, r3)|
        expect(r0.value.evaluate(nil)).to equal(r0.value)
        expect(r1.value.evaluate(nil)).to equal(r1.value)
        expect(r2.value.evaluate(nil)).to equal(r2.value)
        expect(r3.value.evaluate(nil)).to equal(r3.value)
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a Regexp object representing it pattern' do
      node = parse(pkl_string)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          r0: eq(//),
          r1: eq(/(?i)abc/),
          r2: eq(/a(\s*)b(\s*)c/),
          r3: eq(/a(?:\s*)b\(c\)/)
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      s0 = 'Regex("")'
      s1 = 'Regex("(?i)abc")'
      s2 = 'Regex("a(\\\\s*)b(\\\\s*)c")'
      s3 = 'Regex("a(?:\\\\s*)b\\\\(c\\\\)")'
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(r0, r1, r2, r3)|
        expect(r0.value.to_string(nil)).to eq s0
        expect(r0.value.to_pkl_string(nil)).to eq s0

        expect(r1.value.to_string(nil)).to eq s1
        expect(r1.value.to_pkl_string(nil)).to eq s1

        expect(r2.value.to_string(nil)).to eq s2
        expect(r2.value.to_pkl_string(nil)).to eq s2

        expect(r3.value.to_string(nil)).to eq s3
        expect(r3.value.to_pkl_string(nil)).to eq s3
      end
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parse(<<~'PKL')
        r = Regex("foo")
        a = r[0]
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Regex type'
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL')
        a = -Regex("foo")
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Regex type'

      node = parse(<<~'PKL')
        a = !Regex("foo")
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Regex type'
    end
  end

  describe 'binary operation' do
    context 'when defined operation and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = Regex("")
          b = a
        PKL
        strings << <<~'PKL'
          a = Regex(#"a(\s*)b(\s*)c"#)
          b = a
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = Regex("")
        PKL
        strings << <<~'PKL'
          a = Regex(#"a(\s*)b(\s*)c"#)
          b = Regex(#"a(\s*)b(\s*)c"#)
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = Regex("")
          b = Regex(#"a(\s*)b(\s*)c"#)
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = true
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = 1
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = ""
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = List()
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = Set()
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = Map()
        PKL
        strings << <<~'PKL'
          a = Regex("")
          b = IntSeq(0, 0)
        PKL
      end

      it 'should execute the given operation' do
        pkl_match_strings.each do |pkl|
          node = parse(<<~PKL)
            #{pkl}
            c = a == b
            d = a != b
          PKL
          node.evaluate(nil).properties[-2..].then do |(c, d)|
            expect(c.value).to be_boolean(true)
            expect(d.value).to be_boolean(false)
          end
        end

        pkl_unmatch_strings.each do |pkl|
          node = parse(<<~PKL)
            #{pkl}
            c = a != b
            d = a == b
          PKL
          node.evaluate(nil).properties[-2..].then do |(c, d)|
            expect(c.value).to be_boolean(true)
            expect(d.value).to be_boolean(false)
          end
        end
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-', '*', '/', '~/', '%', '**',
          '&&', '||'
        ].each do |op|
          node = parse(<<~PKL)
            a = Regex("") #{op} Regex("")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Regex type"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'pattern' do
      it 'should return the pattern string of this regular expression' do
        node = parse(<<~'PKL')
          a = Regex("").pattern
          b = Regex(#"(?i)abc"#).pattern
          c = Regex(#"a(\s*)b(\s*)c"#).pattern
          d = Regex(#"a(?:\s*)b\(c\)"#).pattern
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('(?i)abc')
          expect(c.value).to be_evaluated_string('a(\\s*)b(\\s*)c')
          expect(d.value).to be_evaluated_string('a(?:\\s*)b\\(c\\)')
        end
      end
    end

    describe 'groupCount' do
      it 'shoul return the number of capturing groups in this regular expression' do
        node = parse(<<~'PKL')
          a = Regex("").groupCount
          b = Regex(#"(?i)abc"#).groupCount
          c = Regex(#"a(\s*)b(\s*)c"#).groupCount
          d = Regex(#"a(?:\s*)b\(c\)"#).groupCount
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(0)
          expect(c.value).to be_int(2)
          expect(d.value).to be_int(0)
        end
      end
    end
  end
end
