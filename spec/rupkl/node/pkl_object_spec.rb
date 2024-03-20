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
end
