# frozen_string_literal: true

RSpec.describe RuPkl::Node::RegexMatch do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_string) do
    <<~'PKL'
      m0 = Regex(#"(abc)|(def)"#).findMatchesIn("xxxabcxxxdefxxxabc")[0]
      m1 = Regex(#"(abc)|(def)"#).findMatchesIn("xxxabcxxxdefxxxabc")[1]
      m2 = Regex(#"(abc)|(def)"#).findMatchesIn("xxxabcxxxdefxxxabc")[2]
    PKL
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(m0, m1, m2)|
        expect(m0.value.evaluate(nil)).to equal(m0.value)
        expect(m1.value.evaluate(nil)).to equal(m1.value)
        expect(m2.value.evaluate(nil)).to equal(m2.value)
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a Hash object representing itself' do
      node = parse(pkl_string)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          m0: match_hash(
            value: 'abc', start: 3, end: 6,
            groups: match_array(
              match_hash(value: 'abc', start: 3, end: 6, groups: be_empty),
              match_hash(value: 'abc', start: 3, end: 6, groups: be_empty),
              be_nil
            )
          ),
          m1: match_hash(
            value: 'def', start: 9, end: 12,
            groups: match_array(
              match_hash(value: 'def', start: 9, end: 12, groups: be_empty),
              be_nil,
              match_hash(value: 'def', start: 9, end: 12, groups: be_empty)
            )
          ),
          m2: match_hash(
            value: 'abc', start: 15, end: 18,
            groups: match_array(
              match_hash(value: 'abc', start: 15, end: 18, groups: be_empty),
              match_hash(value: 'abc', start: 15, end: 18, groups: be_empty),
              be_nil
            )
          )
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing it value' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(m0, m1, m2)|
        expect(m0.value.to_string(nil)).to eq 'abc'
        expect(m0.value.to_pkl_string(nil)).to eq 'abc'

        expect(m1.value.to_string(nil)).to eq 'def'
        expect(m1.value.to_pkl_string(nil)).to eq 'def'

        expect(m2.value.to_string(nil)).to eq 'abc'
        expect(m2.value.to_pkl_string(nil)).to eq 'abc'
      end
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parse(<<~PKL)
        #{pkl_string}
        a = m0[0]
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for RegexMatch type'
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~PKL)
        #{pkl_string}
        a = -m0
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for RegexMatch type'

      node = parse(<<~PKL)
        #{pkl_string}
        a = !m0
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for RegexMatch type'
    end
  end

  describe 'binary operation' do
    context 'when defined operation and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = a
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Regex("foo").matchEntire("foo")
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Regex(#"\w\w\w"#).matchEntire("foo")
        PKL
        strings << <<~'PKL'
          a = Regex("(foo)bar").matchEntire("foobar")
          b = Regex(#"(\w\w\w)\w\w\w"#).matchEntire("foobar")
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Regex("bar").matchEntire("bar")
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Regex("(foo)").matchEntire("foo")
        PKL
        strings << <<~'PKL'
          a = Regex("(foo)foo").matchEntire("foofoo")
          b = Regex("foo(foo)").matchEntire("foofoo")
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = true
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = 1
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = "foo"
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = new Dynamic {
            value = "foo"; start = 0; end = 3
            groups = List(new Dynamic {
              value = "foo"; start = 0; end = 3
              groups = List()
            })}
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = List()
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Set()
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Map()
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = IntSeq(0, 0)
        PKL
        strings << <<~'PKL'
          a = Regex("foo").matchEntire("foo")
          b = Regex("foo")
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

    context 'when the given operation is not defiend' do
      it 'should EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-', '*', '/', '~/', '%', '**',
          '&&', '||'
        ].each do |op|
          node = parse(<<~PKL)
            #{pkl_string}
            a = m0 #{op} m1
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for RegexMatch type"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'value' do
      it 'should return the string value of this match' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = m0.value
          b = m1.value
          c = m2.value
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string('abc')
          expect(b.value).to be_evaluated_string('def')
          expect(c.value).to be_evaluated_string('abc')
        end
      end
    end

    describe 'start' do
      it 'should return the start index of this match' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = m0.start
          b = m1.start
          c = m2.start
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(3)
          expect(b.value).to be_int(9)
          expect(c.value).to be_int(15)
        end
      end
    end

    describe 'end' do
      it 'should return the exclusive end index of this match' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = m0.end
          b = m1.end
          c = m2.end
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(6)
          expect(b.value).to be_int(12)
          expect(c.value).to be_int(18)
        end
      end
    end

    describe 'groups' do
      it 'should return the capturing group matches within this match' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = m0.groups
          b = m1.groups
          c = m2.groups
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_list(
            regexp_match('abc', 3, 6),
            regexp_match('abc', 3, 6),
            null
          )
          expect(b.value).to be_list(
            regexp_match('def', 9, 12),
            null,
            regexp_match('def', 9, 12)
          )
          expect(c.value).to be_list(
            regexp_match('abc', 15, 18),
            regexp_match('abc', 15, 18),
            null
          )
        end
      end
    end
  end
end
