# frozen_string_literal: true

RSpec.describe RuPkl::Node::IntSeq do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = IntSeq(-3, 2)
    PKL
    strings << <<~'PKL'
      a = IntSeq(5, 5)
    PKL
    strings << <<~'PKL'
      a = IntSeq(5, 0)
    PKL
    strings << <<~'PKL'
      a = IntSeq(0, 0)
    PKL
    strings << <<~'PKL'
      a = IntSeq(0, 10)
    PKL
    strings << <<~'PKL'
      a = IntSeq(-10, 0)
    PKL
  end

  describe 'IntSeq method' do
    it 'should create a IntSeq object' do
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(-3, 2)
      end

      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(5, 5)
      end

      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(5, 0)
      end

      node = parse(pkl_strings[3])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(0, 0)
      end

      node = parse(pkl_strings[4])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(0, 10)
      end

      node = parse(pkl_strings[5])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_intseq(-10, 0)
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

      node = parse(pkl_strings[3])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end

      node = parse(pkl_strings[4])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end

      node = parse(pkl_strings[5])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.evaluate(nil)).to equal(a.value)
      end
    end
  end

  describe '#to_ruby' do
    it 'should return an Array object containing elements of this sequence' do
      node = parse(pkl_strings[0])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(-3, -2, -1, 0, 1, 2)
        }
      )

      node = parse(pkl_strings[1])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(5)
        }
      )

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array
        }
      )

      node = parse(pkl_strings[3])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(0)
        }
      )

      node = parse(pkl_strings[4])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        }
      )

      node = parse(pkl_strings[5])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(-10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0)
        }
      )

      node = parse("#{pkl_strings[0]}.step(2)")
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(-3, -1, 1)
        }
      )

      node = parse("#{pkl_strings[0]}.step(-1)")
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array
        }
      )

      node = parse("#{pkl_strings[2]}.step(2)")
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array
        }
      )

      node = parse("#{pkl_strings[2]}.step(-1)")
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_array(5, 4, 3, 2, 1, 0)
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      s = 'IntSeq(-3, 2)'
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(5, 5)'
      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(5, 0)'
      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(0, 0)'
      node = parse(pkl_strings[3])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(0, 10)'
      node = parse(pkl_strings[4])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(-10, 0)'
      node = parse(pkl_strings[5])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(0, 10)'
      node = parse('a = IntSeq(0, 10).step(1)')
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(0, 10).step(2)'
      node = parse('a = IntSeq(0, 10).step(2)')
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'IntSeq(-10, 0).step(-2)'
      node = parse('a = IntSeq(-10, 0).step(-2)')
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end
    end
  end

  describe 'subscript operation' do
    specify 'subscript operation is not defined' do
      node = parse(<<~'PKL')
        a = IntSeq(0, 1)[0]
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'[]\' is not defined for IntSeq type'
    end
  end

  describe 'unary operation' do
    specify 'unary operations are not defined' do
      node = parse(<<~'PKL')
        a = -IntSeq(0, 1)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for IntSeq type'

        node = parse(<<~'PKL')
        a = !IntSeq(0, 1)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for IntSeq type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator is given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = IntSeq(0, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, 0)
          b = IntSeq(-1, 0)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, 1)
          b = IntSeq(-1, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 0)
          b = IntSeq(0, 0)
        PKL
        strings << <<~'PKL'
          a = IntSeq(1, 1)
          b = IntSeq(1, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, -1)
          b = IntSeq(-1, -1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, -1)
          b = IntSeq(0, -2)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, -1)
          b = IntSeq(10, -10)
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = IntSeq(0, 2)
        PKL
        strings << <<~'PKL'
          a = IntSeq(1, 2)
          b = IntSeq(2, 2)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, 0)
          b = IntSeq(-1, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, 0)
          b = IntSeq(-2, 0)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 0)
          b = IntSeq(1, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(-1, -1)
          b = IntSeq(-2, -2)
        PKL
        strings << <<~'PKL'
          a = IntSeq(1, 1)
          b = IntSeq(-1, -1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(1, 0)
          b = IntSeq(0, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, -1)
          b = IntSeq(0, 1)
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = true
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = 1
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = ""
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = List()
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = Map()
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = Set()
        PKL
        strings << <<~'PKL'
          a = IntSeq(0, 1)
          b = Pair(0, 1)
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
          node = parse("a = IntSeq(0, 1) #{op} IntSeq(0, 1)")
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for IntSeq type"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'start' do
      it 'should return the start of this sequence' do
        node = parse(<<~'PKL')
          a = IntSeq(-3, 2).start
          b = IntSeq(2, -3).start
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_int(-3)
          expect(b.value).to be_int(2)
        end
      end
    end

    describe 'end' do
      it 'should return the inclusive end of this sequence' do
        node = parse(<<~'PKL')
          a = IntSeq(-3, 2).end
          b = IntSeq(2, -3).end
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_int(2)
          expect(b.value).to be_int(-3)
        end
      end
    end

    describe 'step (property)' do
      it 'should the common difference of successive members of this sequence' do
        node = parse(<<~'PKL')
          a = IntSeq(-3, 2).step
          b = IntSeq(-3, 2).step(2).step
          c = IntSeq(2, -3).step
          d = IntSeq(2, -3).step(-2).step
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_int(1)
          expect(b.value).to be_int(2)
          expect(c.value).to be_int(1)
          expect(d.value).to be_int(-2)
        end
      end
    end

    describe 'step (method)' do
      it 'should change Changes step to the given value' do
        node = parse(<<~'PKL')
          a = IntSeq(-3, 2).step(2)
          b = IntSeq(2, -3).step(-2)
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_intseq(-3, 2, step: 2)
          expect(b.value).to be_intseq(2, -3, step: -2)
        end
      end

      context 'when the given value is 0' do
        it 'should raise EvaluationError' do
          node = parse(<<~'PKL')
            a = IntSeq(0, 1).step(0)
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected a non zero number, but got \'0\''
        end
      end
    end
  end
end
