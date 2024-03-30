# frozen_string_literal: true

RSpec.describe RuPkl::Node::UnresolvedObject do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string.chomp, root: :object)
  end

  describe '#evaluate' do
    context 'when no class is specified' do
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
            } {
              qux = 6
              7
              ["qux"] = 8
            }
          }
        PKL
      end

      it 'should return Dynamic object containing evaluated members' do
        node = parse(pkl_strings[0])
        expect(node.evaluate(nil)).to be_dynamic

        node = parse(pkl_strings[1])
        expect(node.evaluate(nil)).to (be_dynamic do |o|
          o.element 0
          o.element 1
          o.element 2
        end)

        node = parse(pkl_strings[2])
        expect(node.evaluate(nil)).to (be_dynamic do |o|
          o.property :foo, 1
          o.property :bar, 2
        end)

        node = parse(pkl_strings[3])
        expect(node.evaluate(nil)).to (be_dynamic do |o|
          o.entry 'foo', 1
          o.entry 'bar', 2
        end)

        node = parse(pkl_strings[4])
        expect(node.evaluate(nil)).to (be_dynamic do |o1|
          o1.property :name, 'Pigeon'
          o1.property :lifespan, 8
          o1.element 'wing'
          o1.element 'claw'
          o1.entry 'wing', 'Not related to the _element_ "wing"'
          o1.element 42
          o1.property :extinct, false
          o1.entry false, (
            dynamic do |o2|
              o2.property :description, 'Construed object example'
            end
          )
        end)

        node = parse(pkl_strings[5])
        expect(node.evaluate(nil)).to (be_dynamic do |o1|
          o1.property :foo, (
            dynamic do |o2|
              o2.property :bar, 3
              o2.property :qux, 6
              o2.element 1
              o2.element 4
              o2.element 7
              o2.entry 'baz', 5
              o2.entry 'qux', 8
            end
          )
        end)
      end
    end

    context 'when a property/entry is being defined again' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          { foo = 1 foo = 2 }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'duplicate definition of member'

        node = parse(<<~'PKL')
          { ["foo"] = 1 ["foo"] = 2 }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'duplicate definition of member'
      end
    end
  end
end
