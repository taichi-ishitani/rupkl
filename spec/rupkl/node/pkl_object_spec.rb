# frozen_string_literal: true

RSpec.describe RuPkl::Node::PklObject do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      {}
    PKL
    strings << <<~'PKL'
      { 0 1 2 }
    PKL
    strings << <<~'PKL'
      { foo = 1 bar = 2 }
    PKL
    strings << <<~'PKL'
      { ["foo"] = 1 ["bar"] = 2 }
    PKL
    strings << <<~'PKL'
      {
        name = "Pigeon"
        lifespan = 8
        "wing"
        "claw"
        ["wing"] = "Not related to the _element_ \"wing\""
        42
        extinct = false
        [false] {
          description = "Construed object example"
        }
      }
    PKL
    strings << <<~'PKL'
      {
        foo {
          bar = 0
          1
          ["baz"] = 2
        } {
          bar = 3
          4
          ["baz"] = 5
        }
      }
    PKL
    strings.map(&:chomp)
  end

  describe '#evaluate' do
    it 'should return a new pkl object having evaluated members' do
      node = parser.parse(pkl_strings[0], root: :pkl_object)
      expect(node.evaluate(nil)).to be_pkl_object

      node = parser.parse(pkl_strings[1], root: :pkl_object)
      expect(node.evaluate(nil)).to (be_pkl_object do |o|
        o.element 0
        o.element 1
        o.element 2
      end)

      node = parser.parse(pkl_strings[2], root: :pkl_object)
      expect(node.evaluate(nil)).to (be_pkl_object do |o|
        o.property :foo, 1
        o.property :bar, 2
      end)

      node = parser.parse(pkl_strings[3], root: :pkl_object)
      expect(node.evaluate(nil)).to (be_pkl_object do |o|
        o.entry evaluated_string('foo'), 1
        o.entry evaluated_string('bar'), 2
      end)

      node = parser.parse(pkl_strings[4], root: :pkl_object)
      expect(node.evaluate(nil)).to (be_pkl_object do |o1|
        o1.property :name, evaluated_string('Pigeon')
        o1.property :lifespan, 8
        o1.element evaluated_string('wing')
        o1.element evaluated_string('claw')
        o1.entry evaluated_string('wing'), evaluated_string('Not related to the _element_ "wing"')
        o1.element 42
        o1.property :extinct, false
        o1.entry false, (
          pkl_object { |o2| o2.property(:description, evaluated_string('Construed object example')) }
        )
      end)

      node = parser.parse(pkl_strings[5], root: :pkl_object)
      expect(node.evaluate(nil)).to (be_pkl_object do |o1|
        o1.property :foo, (
          pkl_object do |o2|
            o2.property :bar, 3
            o2.element 1
            o2.element 4
            o2.entry evaluated_string('baz'), 5
          end
        )
      end)
    end
  end

  describe '#to_ruby' do
    it 'should return a Pkl object containg evaluated members' do
      node = parser.parse(pkl_strings[0], root: :pkl_object)
      expect(node.to_ruby(nil)).to match_pkl_object

      node = parser.parse(pkl_strings[1], root: :pkl_object)
      expect(node.to_ruby(nil))
        .to match_pkl_object(elements: [0, 1, 2])

      node = parser.parse(pkl_strings[2], root: :pkl_object)
      expect(node.to_ruby(nil))
        .to match_pkl_object(properties: { foo: 1, bar: 2 })

      node = parser.parse(pkl_strings[3], root: :pkl_object)
      expect(node.to_ruby(nil))
        .to match_pkl_object(entries: { 'foo' => 1, 'bar' => 2 })

      node = parser.parse(pkl_strings[4], root: :pkl_object)
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            name: 'Pigeon', lifespan: 8, extinct: false
          },
          elements: [
            'wing', 'claw', 42
          ],
          entries: {
            'wing' => 'Not related to the _element_ "wing"',
            false => match_pkl_object(
              properties: { description: 'Construed object example' }
            )
          }
        )

      node = parser.parse(pkl_strings[5], root: :pkl_object)
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            foo: match_pkl_object(
              properties: { bar: 3 },
              elements: [1, 4],
              entries: { 'baz' => 5 }
            )
          }
        )
    end
  end

  describe 'subscript operation' do
    context 'when the given key mathes an element index' do
      it 'should return the specified element' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[2]
          bar_1 = foo[1]
          bar_2 = foo[0]
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-3].value).to be_integer(2)
          expect(n.properties[-2].value).to be_integer(1)
          expect(n.properties[-1].value).to be_integer(0)
        end
      end
    end

    context 'when the given key matches an entry key' do
      it 'should return the specified entry' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            [false] = 1
            ["foo"] = 2
            [0] = 3
          }
          bar_0 = foo[0]
          bar_1 = foo["foo"]
          bar_2 = foo[false]
          bar_3 = foo[true]
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-4].value).to be_integer(3)
          expect(n.properties[-3].value).to be_integer(2)
          expect(n.properties[-2].value).to be_integer(1)
          expect(n.properties[-1].value).to be_integer(0)
        end
      end
    end

    context 'when no elements/entries are not found' do
      it 'should raise EvaluationError' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[-1]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'-1\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[3]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'3\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            ["foo"] = 1
            [0] = 2
          }
          bar_0 = foo[false]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'false\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            ["foo"] = 1
            [0] = 2
          }
          bar_0 = foo["bar"]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'"bar"\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            ["foo"] = 1
            [0] = 2
          }
          bar_0 = foo[-1]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'-1\''
      end
    end
  end
end
