# frozen_string_literal: true

RSpec.describe RuPkl::Node::Map do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = Map()
    PKL
    strings << <<~'PKL'
      a = Map(1, "one", 2, "two", 3, "three")
    PKL
    strings << <<~'PKL'
      a = Map(1, "x", 2, Map(3, 4))
    PKL
  end

  describe 'Map method' do
    it 'should create Map object containing the given entries' do
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map
      end

      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'one', 2 => 'two', 3 => 'three' })
      end

      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'x', 2 => map({ 3 => 4 }) })
      end

      node = parse(<<~'PKL')
        a = Map(1, 1, 2, 2, 1, 3, 2, 4)
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 3, 2 => 4 })
      end

      node = parse(<<~'PKL')
        a = Map(1, 1, 2, 2, 1, "three", 2, "four")
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'three', 2 => 'four' })
      end
    end

    context 'when the number of the given arguments is not a multiple of 2' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          a = Map(1)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'number of arguments must be a multiple of two'

        node = parse(<<~'PKL')
          a = Map(1, 2, 3)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'number of arguments must be a multiple of two'
      end
    end
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end

      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end

      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a PklObject object containing its entries' do
      node = parse(pkl_strings[0])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_pkl_object
        }
      )

      node = parse(pkl_strings[1])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_pkl_object(
            entries: { 1 => 'one', 2 => 'two', 3 => 'three' }
          )
        }
      )

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_pkl_object(
            entries: {
              1 => 'x',
              2 => match_pkl_object(entries: { 3 => 4 })
            }
          )
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      s = 'Map()'
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'Map(1, "one", 2, "two", 3, "three")'
      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'Map(1, "x", 2, Map(3, 4))'
      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end
    end
  end

  describe 'subscript operation' do
    context 'when the given key matches an entry key' do
      it 'should return the specified entry' do
        node = parse(<<~'PKL')
          m0 = Map(1, 1, "two", 2, "three", 3)
          m1 = Map(30, new Dynamic { name = "Pigeon" }, new Dynamic { name = "Pigeon" }, 30, 1, 1)
          a = m0[1]
          b = m0["two"]
          c = m0["three"]
          d = m1[30]
          e = m1[new Dynamic { name = "Pigeon" }]
          f = m1[1]
        PKL
        node.evaluate(nil).properties[-6..].then do |(a, b, c, d, e, f)|
          expect(a.value).to be_int(1)
          expect(b.value).to be_int(2)
          expect(c.value).to be_int(3)
          expect(d.value).to(be_dynamic { |d| d.property :name, 'Pigeon' })
          expect(e.value).to be_int(30)
          expect(f.value).to be_int(1)
        end
      end
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL')
        a = -Map(0, 1)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Map type'

      node = parse(<<~'PKL')
        a = !Map(0, 1)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Map type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = Map()
          b = Map()
        PKL
        strings << <<~'PKL'
          a = Map(1, 1, "two", 2, "three", 3)
          b = Map(1, 1, "two", 2, "three", 3)
        PKL
        strings << <<~'PKL'
          a = Map(1, 1, "two", 2, "three", 3)
          b = Map("three", 3, 1, 1, "two", 2)
        PKL
        strings << <<~'PKL'
          m0 = Map(0, 1, 2, 3)
          m1 = Map(4, 5, 6, 7)
          a = Map(m0, m1)
          b = Map(m0, m1)
        PKL
        strings << <<~'PKL'
          m0 = Map(0, 1, 2, 3)
          m1 = Map(4, 5, 6, 7)
          m2 = Map(2, 3, 0, 1)
          m3 = Map(6, 7, 4, 5)
          a = Map(m0, m1)
          b = Map(m2, m3)
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = Map()
          b = Map(0, 1)
        PKL
        strings << <<~'PKL'
          a = Map(0, 1, 2, 3)
          b = Map(0, 1, 2, 4)
        PKL
        strings << <<~'PKL'
          a = Map(0, 1, 2, 3)
          b = Map(0, 1, 4, 3)
        PKL
        strings << <<~'PKL'
          a = Map(0, 1)
          b = Map(0, 1, 2, 3)
        PKL
        strings << <<~'PKL'
          m0 = Map(0, 1)
          m1 = Map(0, 2)
          a = Map(m0, 3)
          b = Map(m1, 3)
        PKL
        strings << <<~'PKL'
          m0 = Map(0, 1)
          m1 = Map(0, 2)
          a = Map(3, m0)
          b = Map(3, m1)
        PKL
        strings << <<~'PKL'
          a = Map()
          b = true
        PKL
        strings << <<~'PKL'
          a = Map()
          b = 1
        PKL
        strings << <<~'PKL'
          a = Map()
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = Map()
          b = ""
        PKL
        strings << <<~'PKL'
          a = Map()
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = Map()
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = Map()
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = Map()
          b = List()
        PKL
        strings << <<~'PKL'
          a = Map()
          b = Set()
        PKL
        strings << <<~'PKL'
          a = Map(0, 1)
          b = Pair(0, 1)
        PKL
        strings << <<~'PKL'
          a = Map(0, 1)
          b = IntSeq(0, 1)
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

        node = parse(<<~'PKL')
          m0 = Map(1, 1, "two", 2, "three", 3)
          m1 = Map(4, 4, "five", 5, "six", 6)
          m2 = Map(1, "one", "two", "two", "three", "three")
          m3 = Map(1, 11)
          m4 = Map(1, 1, 2, 2)
          a = m0 + m0
          b = m0 + m1
          c = m0 + m2
          d = Map() + Map()
          e = m0 + Map()
          f = Map() + m0
          g = m3 + m4
          h = m4 + m3
        PKL
        node.evaluate(nil).properties[-8..].then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_map({ 1 => 1, 'two' => 2, 'three' => 3 })
          expect(b.value).to be_map({ 1 => 1, 'two' => 2, 'three' => 3, 4 => 4, 'five' => 5, 'six' => 6 })
          expect(c.value).to be_map({ 1 => 'one', 'two' => 'two', 'three' => 'three' })
          expect(d.value).to be_map
          expect(e.value).to be_map({ 1 => 1, 'two' => 2, 'three' => 3 })
          expect(f.value).to be_map({ 1 => 1, 'two' => 2, 'three' => 3 })
          expect(g.value).to be_map({ 1 => 1, 2 => 2 })
          expect(h.value).to be_map({ 1 => 11, 2 => 2 })
        end
      end
    end

    context 'when the given operator is not defined' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '-', '*', '/', '~/', '%', '**',
          '&&', '||'
        ].each do |op|
          node = parse("a = Map() #{op} Map()")
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Map type"
        end
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        node = parse('a = Map() + true')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Boolean is given for operator \'+\''

        node = parse('a = Map() + 1')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Int is given for operator \'+\''

        node = parse('a = Map() + 1.0')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Float is given for operator \'+\''

        node = parse('a = Map() + new Dynamic {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Dynamic is given for operator \'+\''

        node = parse('a = Map() + new Mapping {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Mapping is given for operator \'+\''

        node = parse('a = Map() + new Listing {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Listing is given for operator \'+\''

        node = parse('a = Map() + List()')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type List is given for operator \'+\''

        node = parse('a = Map() + Set()')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Set is given for operator \'+\''

        node = parse('a = Map() + Pair(0, 1)')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Pair is given for operator \'+\''
      end
    end
  end

  describe 'builtin property' do
    describe 'length' do
      it 'should return the number of entries in this map' do
        node = parse(<<~'PKL')
          m0 = Map()
          m1 = Map("one", 1, "two", 2, "three", 3)
          a = m0.length
          b = m1.length
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(3)
        end
      end
    end

    describe 'isEmpty' do
      it 'should tell whether this map is empty' do
        node = parse(<<~'PKL')
          m0 = Map()
          m1 = Map("one", 1, "two", 2, "three", 3)
          a = m0.isEmpty
          b = m1.isEmpty
        PKL
        node.evaluate(nil).properties[-2..].then do |(a, b)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(false)
        end
      end
    end

    describe 'keys' do
      it 'should return the keys contained in this map' do
        node = parse(<<~'PKL')
          m0 = Map()
          m1 = Map("one", 1, "two", 2, "three", 3)
          m2 = Map("one", 1, "two", 2) + Map("three", 3, "four", 4)
          a = m0.keys
          b = m1.keys
          c = m2.keys
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_set
          expect(b.value).to be_set('one', 'two', 'three')
          expect(c.value).to be_set('one', 'two', 'three', 'four')
        end
      end
    end

    describe 'values' do
      it 'should return the values contained in this map' do
        node = parse(<<~'PKL')
          m0 = Map()
          m1 = Map("one", 1, "two", 2, "three", 3)
          m2 = Map("one", 1, "two", 2) + Map("three", 3, "four", 4)
          a = m0.values
          b = m1.values
          c = m2.values
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_list
          expect(b.value).to be_list(1, 2, 3)
          expect(c.value).to be_list(1, 2, 3, 4)
        end
      end
    end

    describe 'entries' do
      it 'should the entries contained in this map' do
        node = parse(<<~'PKL')
          m0 = Map()
          m1 = Map("one", 1, "two", 2, "three", 3)
          m2 = Map("one", 1, "two", 2) + Map("three", 3, "four", 4)
          a = m0.entries
          b = m1.entries
          c = m2.entries
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_list
          expect(b.value).to be_list(pair('one', 1), pair('two', 2), pair('three', 3))
          expect(c.value).to be_list(pair('one', 1), pair('two', 2), pair('three', 3), pair('four', 4))
        end
      end
    end
  end
end
