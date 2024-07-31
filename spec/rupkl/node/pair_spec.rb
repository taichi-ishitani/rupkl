# frozen_string_literal: true

RSpec.describe RuPkl::Node::Pair do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      p0 = Pair("Pigeon", 42)
    PKL
    strings << <<~'PKL'
      p1 = Pair(new Dynamic { name = "Pigeon" }, List(1, 2, 3))
    PKL
    strings << <<~'PKL'
      p2 = Pair(null, Pair("Pigeon", 42))
    PKL
    strings
  end

  let(:pkl_string) do
    <<~PKL
      #{pkl_strings[0]}
      #{pkl_strings[1]}
      #{pkl_strings[2]}
    PKL
  end

  describe 'Pair method' do
    it 'should create Pair object' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(p0, p1, p2)|
        expect(p0.value).to be_pair('Pigeon', 42)
        expect(p1.value).to be_pair(dynamic { |d| d.property :name, 'Pigeon' }, list(1, 2, 3))
        expect(p2.value).to be_pair(null, pair('Pigeon', 42))
      end
    end
  end

  describe '#evaluate' do
    it 'should return itself' do
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(p0, p1, p2)|
        expect(p0.value.evaluate(nil)).to equal(p0.value)
        expect(p1.value.evaluate(nil)).to equal(p1.value)
        expect(p2.value.evaluate(nil)).to equal(p2.value)
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a PklObject object containing its elements' do
      node = parse(pkl_string)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          p0: match_pkl_object(
            properties: {
              first: 'Pigeon',
              second: 42
            }
          ),
          p1: match_pkl_object(
            properties: {
              first: match_pkl_object(properties: { name: 'Pigeon' }),
              second: match_pkl_object(elements: [1, 2, 3])
            }
          ),
          p2: match_pkl_object(
            properties: {
              first: be_nil,
              second: match_pkl_object(properties: { first: 'Pigeon', second: 42 })
            }
          )
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      s0 = 'Pair("Pigeon", 42)'
      s1 = 'Pair(new Dynamic { name = "Pigeon" }, List(1, 2, 3))'
      s2 = 'Pair(null, Pair("Pigeon", 42))'
      node = parse(pkl_string)
      node.evaluate(nil).properties.then do |(p0, p1, p2)|
        expect(p0.value.to_string(nil)).to eq s0
        expect(p0.value.to_pkl_string(nil)).to eq s0

        expect(p1.value.to_string(nil)).to eq s1
        expect(p1.value.to_pkl_string(nil)).to eq s1

        expect(p2.value.to_string(nil)).to eq s2
        expect(p2.value.to_pkl_string(nil)).to eq s2
      end
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parse(<<~'PKL')
        a = Pair(1, 2)
        b = a[0]
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for Pair type'
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL')
        a = -Pair(1, 2)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Pair type'

      node = parse(<<~'PKL')
        a = !Pair(1, 2)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Pair type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Pair(0, 1)
        PKL
        strings << <<~'PKL'
          p0 = Pair(0, 1)
          p1 = Pair(2, 3)
          a = Pair(p0, p1)
          b = Pair(p0, p1)
        PKL
        strings << <<~'PKL'
          p0 = Pair(0, 1)
          p1 = Pair(2, 3)
          p2 = Pair(0, 1)
          p3 = Pair(2, 3)
          a = Pair(p0, p1)
          b = Pair(p2, p3)
        PKL
        strings
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Pair(2, 3)
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Pair(0, 2)
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Pair(2, 1)
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = true
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = 1
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = ""
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = List(0, 1)
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Set(0, 1)
        PKL
        strings << <<~'PKL'
          a = Pair(0, 1)
          b = Map(0, 1)
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
            a = Pair(0, 1) #{op} Pair(2, 3)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Pair type"
        end
      end
    end
  end

  describe 'buildin property' do
    describe 'first/key' do
      it 'should return the first element' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = p0.first
          b = p1.first
          c = p2.first
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string('Pigeon')
          expect(b.value).to(be_dynamic { |d| d.property :name, 'Pigeon' })
          expect(c.value).to be_null
        end

        node = parse(<<~PKL)
          #{pkl_string}
          a = p0.key
          b = p1.key
          c = p2.key
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_evaluated_string('Pigeon')
          expect(b.value).to(be_dynamic { |d| d.property :name, 'Pigeon' })
          expect(c.value).to be_null
        end
      end
    end

    describe 'second/value' do
      it 'should return the second element' do
        node = parse(<<~PKL)
          #{pkl_string}
          a = p0.second
          b = p1.second
          c = p2.second
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(42)
          expect(b.value).to be_list(1, 2, 3)
          expect(c.value).to be_pair('Pigeon', 42)
        end

        node = parse(<<~PKL)
          #{pkl_string}
          a = p0.value
          b = p1.value
          c = p2.value
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(42)
          expect(b.value).to be_list(1, 2, 3)
          expect(c.value).to be_pair('Pigeon', 42)
        end
      end
    end
  end
end
