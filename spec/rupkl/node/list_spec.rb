# frozen_string_literal: true

RSpec.describe RuPkl::Node::List do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = List()
    PKL
    strings << <<~'PKL'
      a = List(1, 2, 3)
    PKL
    strings << <<~'PKL'
      a = List(1, "x", List(1, 2, 3))
    PKL
    strings
  end

  describe 'List method' do
    it 'should create a List object containing the given elements' do
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list
      end

      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list(1, 2, 3)
      end

      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list(1, 'x', list(1, 2, 3))
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
    it 'should return a PklObject containing its elements' do
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
            elements: [1, 2, 3]
          )
        }
      )

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          a: match_pkl_object(
            elements: [
              1, 'x', match_pkl_object(elements: [1, 2, 3])
            ]
          )
        }
      )
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      s = 'List()'
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'List(1, 2, 3)'
      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end

      s = 'List(1, "x", List(1, 2, 3))'
      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value.to_string(nil)).to eq s
        expect(a.value.to_pkl_string(nil)).to eq s
      end
    end
  end

  describe 'subscript operation' do
    context 'when the given index matches an element index' do
      it 'should return the specified element' do
        node = parse(<<~'PKL')
          list = List(0, 1, List(2, 3, 4))
          a = list[0]
          b = list[1]
          c = list[2]
          d = list[2][0]
          e = list[2][1]
          f = list[2][2]
        PKL
        node.evaluate(nil).properties[-6..].then do |(a, b, c, d, e, f)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(1)
          expect(c.value).to be_list(2, 3, 4)
          expect(d.value).to be_int(2)
          expect(e.value).to be_int(3)
          expect(f.value).to be_int(4)
        end
      end
    end

    context 'when no element is found' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          a = List(0, 1, 2)
          b = a[-1]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '-1'"

        node = parse(<<~'PKL')
          a = List(0, 1, 2)
          b = a[3]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '3'"

        node = parse(<<~'PKL')
          a = List(0, 1, 2)
          b = a[1.0]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '1.0'"

        node = parse(<<~'PKL')
          a = List(0, 1, 2)
          b = a["0"]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '\"0\"'"

        node = parse(<<~'PKL')
          a = List(0, 1, 2)
          b = a[true]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key 'true'"
      end
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL')
        a = -List(0, 1, 2)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for List type'

      node = parse(<<~'PKL')
        a = !List(0, 1, 2)
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for List type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = List()
          b = List()
        PKL
        strings << <<~'PKL'
          a = List(0, 1)
          b = List(0, 1)
        PKL
        strings << <<~'PKL'
          l0 = List(0, 1)
          l1 = List(2, 3)
          a = List(l0, l1)
          b = List(l0, l1)
        PKL
        strings << <<~'PKL'
          l0 = List(0, 1)
          l1 = List(0, 1)
          a = List(l0)
          b = List(l1)
        PKL
        strings
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = List()
          b = List(0)
        PKL
        strings << <<~'PKL'
          a = List(0)
          b = List(1)
        PKL
        strings << <<~'PKL'
          a = List(0)
          b = List(0, 1)
        PKL
        strings << <<~'PKL'
          a = List(0, 1)
          b = List(1, 0)
        PKL
        strings << <<~'PKL'
          l0 = List(0, 1)
          l1 = List(2, 3)
          a = List(l0)
          b = List(l1)
        PKL
        strings << <<~'PKL'
          a = List()
          b = true
        PKL
        strings << <<~'PKL'
          a = List()
          b = 1
        PKL
        strings << <<~'PKL'
          a = List()
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = List()
          b = ""
        PKL
        strings << <<~'PKL'
          a = List()
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = List()
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = List()
          b = new Listing {}
        PKL
        strings
      end

      it 'should evaluate the given operation' do
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
          l0 = List(1, "two", 3)
          l1 = List(1, "two", 4)
          a = l0 + l1
          b = List() + List()
          c = l0 + List()
          d = List() + l1
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_list(1, 'two', 3, 1, 'two', 4)
          expect(b.value).to be_list()
          expect(c.value).to be_list(1, 'two', 3)
          expect(d.value).to be_list(1, 'two', 4)
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
          node = parse("a = List() #{op} List()")
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for List type"
        end
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        node = parse('a = List() + true')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Boolean is given for operator \'+\''

        node = parse('a = List() + 1')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Int is given for operator \'+\''

        node = parse('a = List() + 1.0')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Float is given for operator \'+\''

        node = parse('a = List() + new Dynamic {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Dynamic is given for operator \'+\''

        node = parse('a = List() + new Mapping {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Mapping is given for operator \'+\''

        node = parse('a = List() + new Listing {}')
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'invalid operand type Listing is given for operator \'+\''
      end
    end
  end
end