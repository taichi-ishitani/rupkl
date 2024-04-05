# frozen_string_literal: true

RSpec.describe RuPkl::Node::UnresolvedObject do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string.chomp, root: :object)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      {}
    PKL
    strings << <<~'PKL'
      { 1 2 1 + 2 }
    PKL
    strings << <<~'PKL'
      { foo = 1 bar = 2 baz = 1 + 2 }
    PKL
    strings << <<~'PKL'
      { ["foo"] = 1 ["bar"] = 2 ["baz"] = 1 + 2 }
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
          bar = 1
          2
          ["baz"] = 1 + 2
        } {
          bar = 3
          4
          ["baz"] = 3 + 4
        } {
          qux = 5
          6
          ["qux"] = 5 + 6
        }
      }
    PKL
  end

  describe '#evaluate' do
    context 'when no class is specified' do
      it 'should return Dynamic object containing members eagerly evaluated' do
        node = parse(pkl_strings[0])
        expect(node.evaluate(nil)).to be_dynamic

        node = parse(pkl_strings[1])
        expect(node.evaluate(nil)).to (
          be_dynamic do |o|
            o.element 1
            o.element 2
            o.element 3
          end
        )

        node = parse(pkl_strings[2])
        expect(node.evaluate(nil)).to (
          be_dynamic do |o|
            o.property :foo, 1
            o.property :bar, 2
            o.property :baz, 3
          end
        )

        node = parse(pkl_strings[3])
        expect(node.evaluate(nil)).to (
          be_dynamic do |o|
            o.entry 'foo', 1
            o.entry 'bar', 2
            o.entry 'baz', 3
          end
        )

        node = parse(pkl_strings[4])
        expect(node.evaluate(nil)).to (
          be_dynamic do |o1|
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
          end
        )

        node = parse(pkl_strings[5])
        expect(node.evaluate(nil)).to (
          be_dynamic do |o1|
            o1.property :foo, (
              dynamic do |o2|
                o2.property :bar, 3
                o2.property :qux, 5
                o2.element 2
                o2.element 4
                o2.element 6
                o2.entry 'baz', 7
                o2.entry 'qux', 11
              end
            )
          end
        )
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

  describe '#evaluate_lazily' do
    context 'when no class is specified' do
      it 'should return a Dynamic object containing members evaluated lazily' do
        node = parse(pkl_strings[0])
        expect(node.evaluate_lazily(nil)).to be_dynamic

        node = parse(pkl_strings[1])
        expect(node.evaluate_lazily(nil)).to (
          be_dynamic do |o|
            o.element 1
            o.element 2
            o.element b_op(:+, 1, 2)
          end
        )

        node = parse(pkl_strings[2])
        expect(node.evaluate_lazily(nil)).to (
          be_dynamic do |o|
            o.property :foo, 1
            o.property :bar, 2
            o.property :baz, b_op(:+, 1, 2)
          end
        )

        node = parse(pkl_strings[3])
        expect(node.evaluate_lazily(nil)).to (
          be_dynamic do |o|
            o.entry 'foo', 1
            o.entry 'bar', 2
            o.entry 'baz', b_op(:+, 1, 2)
          end
        )

        node = parse(pkl_strings[4])
        n = node.evaluate_lazily(nil)
        expect(node.evaluate_lazily(nil)).to (
          be_dynamic do |o1|
            o1.property :name, 'Pigeon'
            o1.property :lifespan, 8
            o1.element 'wing'
            o1.element 'claw'
            o1.entry 'wing', 'Not related to the _element_ "wing"'
            o1.element 42
            o1.property :extinct, false
            o1.entry false, (
              unresolved_object do |o2|
                o2.body { |b| b.property :description, 'Construed object example' }
              end
            )
          end
        )

        node = parse(pkl_strings[5])
        expect(node.evaluate_lazily(nil)).to (
          be_dynamic do |o1|
            o1.property :foo, (
              unresolved_object do |o2|
                o2.body { |b| b.property :bar, 1; b.element 2; b.entry 'baz', b_op(:+, 1, 2) }
                o2.body { |b| b.property :bar, 3; b.element 4; b.entry 'baz', b_op(:+, 3, 4) }
                o2.body { |b| b.property :qux, 5; b.element 6; b.entry 'qux', b_op(:+, 5, 6) }
              end
            )
          end
        )
      end
    end

    context 'when a property/entry is being defined again' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          { foo = 1 foo = 2 }
        PKL
        expect { node.evaluate_lazily(nil) }
          .to raise_evaluation_error 'duplicate definition of member'

        node = parse(<<~'PKL')
          { ["foo"] = 1 ["foo"] = 2 }
        PKL
        expect { node.evaluate_lazily(nil) }
          .to raise_evaluation_error 'duplicate definition of member'
      end
    end
  end
end
