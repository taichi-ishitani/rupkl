# frozen_string_literal: true

RSpec.describe RuPkl::Node::UnresolvedObject do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :object)
    parser.parse(string.chomp, root: root)
  end

  describe 'object creation' do
    context 'when no type is specified' do
      it 'should return a Dyanmic object' do
        node = parse(<<~'PKL')
          {}
        PKL
        expect(node.evaluate(nil)).to be_dynamic
      end
    end

    context 'when a type is specified' do
      it 'should return a object of which type is the given type' do
        node = parse(<<~'PKL', root: :expression)
          new Dynamic {}
        PKL
        expect(node.evaluate(nil)).to be_dynamic

        node = parse(<<~'PKL', root: :expression)
          new Mapping {}
        PKL
        expect(node.evaluate(nil)).to be_mapping

        node = parse(<<~'PKL', root: :expression)
          new Listing {}
        PKL
        expect(node.evaluate(nil)).to be_listing
      end
    end

    context 'when tie specified type is not found' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL', root: :expression)
          new Foo {}
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find type \'Foo\''
      end
    end

    context 'when the specified type is not instantiable' do
      it 'should raise EvaluationError' do
        [:Int, :Float, :Boolean, :String].each do |klass|
          node = parse(<<~PKL, root: :expression)
            new #{klass} {}
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "cannot instantiate class '#{klass}'"
        end

        [:Any, :Module].each do |klass|
          node = parse(<<~PKL, root: :expression)
            new #{klass} {}
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "cannot instantiate abstract class '#{klass}'"
        end
      end
    end

    context 'when a proprety/entry is being defined twice in the same {} block' do
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

    context 'when multiple blocks are given' do
      specify 'existing property/entry is overwrite' do
        node = parse(<<~'PKL')
          { foo = 1 ["bar"] = 2 }{ foo = 3 }{ ["bar"] = 4 }
        PKL
        expect(node.evaluate(nil)).to (
          be_dynamic do |o|
            o.property :foo, 3
            o.entry 'bar', 4
          end
        )

        node = parse(<<~'PKL')
          {
            foo {
              foo = 1 ["bar"] = 2
            }
          }{
            foo {
              baz = 3 ["bar"] = 4
            }
          }{
            foo {
              foo = 5 ["qux"] = 6
            }
          }
        PKL
        expect(node.evaluate(nil)).to (
          be_dynamic do |o1|
            o1.property :foo, (
              dynamic do |o2|
                o2.property :foo, 5; o2.property :baz, 3
                o2.entry 'bar', 4;o2.entry 'qux', 6
              end
            )
          end
        )
      end

      specify 'elements are merged' do
        node = parse(<<~'PKL')
          { 0 1 }{ "foo" "bar" }{ true false }
        PKL
        expect(node.evaluate(nil)).to (
          be_dynamic do |o|
            o.element 0; o.element 1; o.element 'foo'
            o.element 'bar'; o.element true; o.element false
          end
        )
      end
    end
  end

  let(:pkl_strings) do
    strings = []
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
        }{
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
    it 'should return an object containing members eagerly evaluated' do
      node = parse(pkl_strings[0])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o|
          o.element 1
          o.element 2
          o.element 3
        end
      )

      node = parse(pkl_strings[1])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o|
          o.property :foo, 1
          o.property :bar, 2
          o.property :baz, 3
        end
      )

      node = parse(pkl_strings[2])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o|
          o.entry 'foo', 1
          o.entry 'bar', 2
          o.entry 'baz', 3
        end
      )

      node = parse(pkl_strings[3])
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

      node = parse(pkl_strings[4])
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

  describe '#evaluate_lazily' do
    it 'should return an object containing members evaluated lazily' do
      node = parse(pkl_strings[0])
      expect(node.evaluate_lazily(nil)).to (
        be_dynamic do |o|
          o.element 1
          o.element 2
          o.element b_op(:+, 1, 2)
        end
      )

      node = parse(pkl_strings[1])
      expect(node.evaluate_lazily(nil)).to (
        be_dynamic do |o|
          o.property :foo, 1
          o.property :bar, 2
          o.property :baz, b_op(:+, 1, 2)
        end
      )

      node = parse(pkl_strings[2])
      expect(node.evaluate_lazily(nil)).to (
        be_dynamic do |o|
          o.entry 'foo', 1
          o.entry 'bar', 2
          o.entry 'baz', b_op(:+, 1, 2)
        end
      )

      node = parse(pkl_strings[3])
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
            dynamic do |o2|
              o2.property :description, 'Construed object example'
            end
          )
        end
      )

      node = parse(pkl_strings[4])
      n = node.evaluate_lazily(nil)
      expect(node.evaluate_lazily(nil)).to (
        be_dynamic do |o1|
          o1.property :foo, (
            dynamic do |o2|
              o2.property :bar, 3
              o2.property :qux, 5
              o2.entry 'baz', b_op(:+, 3, 4)
              o2.entry 'qux', b_op(:+, 5, 6)
              o2.element 2
              o2.element 4
              o2.element 6
            end
          )
        end
      )
    end
  end
end
