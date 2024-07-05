# frozen_string_literal: true

RSpec.describe RuPkl::Node::Dynamic do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      {}
    PKL
    strings << <<~'PKL'
      { 0 1 1 + 1 }
    PKL
    strings << <<~'PKL'
      { foo = 0 bar = 1 baz = 1 + 1 }
    PKL
    strings << <<~'PKL'
      { ["foo"] = 0 ["bar"] = 1 ["baz"] = 1 + 1 }
    PKL
    strings << <<~'PKL'
      {
        name = "Pigeon"
        lifespan = 8
        "wing"
        "claw"
        ["wing"] = "Not related to \nthe _element_ \"wing\""
        42
        extinct = false
        [false] {
          description = "Construed object example"
        }
      }
    PKL
    strings << <<~'PKL'
      {
        bird {
          name = "Pigeon"
          diet = "Seeds"
          taxonomy {
            kingdom = "Animalia"
            clade = "Dinosauria"
            order = "Columbiformes"
          }
        }
        parrot = (bird) {
          name = "Parrot"
          diet = "Berries"
          taxonomy {
            order = "Psittaciformes"
          }
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
    strings << <<~'PKL'
      {
        foo_0 = 0
        foo_1 = foo_0 + 1
        bar {
          bar_0 = foo_1 + 1
          bar_1 = bar_0 + 1
        }
      }
    PKL
    strings << <<~'PKL'
      {
        foo = 1 + 2
        bar {
          foo = 2 + 3
          [foo] = 3 + 4
        }
      }
    PKL
    strings << <<~'PKL'
      {
        foo = 1
        bar = this
      }
    PKL
  end

  def parse(string, root: :object)
    parser.parse(string.chomp, root: root)
  end

  describe '#evaluate' do
    it 'should return a Dynamic object containing members eagerly evaluated' do
      node = parse(pkl_strings[0])
      expect(node.evaluate(nil)).to be_dynamic

      node = parse(pkl_strings[1])
      expect(node.evaluate(nil))
        .to (be_dynamic { |o| o.element 0; o.element 1; o.element 2 })

      node = parse(pkl_strings[2])
      expect(node.evaluate(nil))
        .to (be_dynamic { |o| o.property :foo, 0; o.property :bar, 1; o.property :baz, 2 })

      node = parse(pkl_strings[3])
      expect(node.evaluate(nil))
        .to (be_dynamic { |o| o.entry 'foo', 0; o.entry 'bar', 1; o.entry 'baz', 2 })

      node = parse(pkl_strings[4])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o1|
          o1.property :name, 'Pigeon'
          o1.property :lifespan, 8
          o1.element 'wing'
          o1.element 'claw'
          o1.entry 'wing', "Not related to \nthe _element_ \"wing\""
          o1.element 42
          o1.property :extinct, false
          o1.entry false, (
            dynamic { |o2| o2.property :description, 'Construed object example' }
          )
        end
      )

      node = parse(pkl_strings[5])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o1|
          o1.property :bird, (
            dynamic do |o2|
              o2.property :name, 'Pigeon'
              o2.property :diet, 'Seeds'
              o2.property :taxonomy, (
                dynamic do |o3|
                  o3.property :kingdom, 'Animalia'
                  o3.property :clade, 'Dinosauria'
                  o3.property :order, 'Columbiformes'
                end
              )
            end
          )
          o1.property :parrot, (
            dynamic do |o2|
              o2.property :name, 'Parrot'
              o2.property :diet, 'Berries'
              o2.property :taxonomy, (
                dynamic do |o3|
                  o3.property :kingdom, 'Animalia'
                  o3.property :clade, 'Dinosauria'
                  o3.property :order, 'Psittaciformes'
                end
              )
            end
          )
        end
      )

      node = parse(pkl_strings[6])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o1|
          o1.property :foo, (
            dynamic do |o2|
              o2.property :bar, 3; o2.entry 'baz', 5; o2.element 1; o2.element 4
            end
          )
        end
      )

      node = parse(pkl_strings[7])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o1|
          o1.property :foo_0, 0; o1.property :foo_1, 1
          o1.property :bar, (
            dynamic do |o2|
              o2.property :bar_0, 2; o2.property :bar_1, 3
            end
          )
        end
      )

      node = parse(pkl_strings[8])
      expect(node.evaluate(nil)).to (
        be_dynamic do |o1|
          o1.property :foo, 3
          o1.property :bar, (
            dynamic do |o2|
              o2.property :foo, 5
              o2.entry 3, 7
            end
          )
        end
      )

      node = parse(pkl_strings[9])
      node.evaluate(nil).then do |n|
        expect(n).to (
          be_dynamic { |o| o.property :foo, 1; o.property :bar, equal(n) }
        )
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a PklObject object contating evaluated members' do
      node = parse(pkl_strings[0])
      expect(node.to_ruby(nil)).to match_pkl_object

      node = parse(pkl_strings[1])
      expect(node.to_ruby(nil))
        .to match_pkl_object(elements: [0, 1, 2])

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil))
        .to match_pkl_object(properties: { foo: 0, bar: 1, baz: 2 })

      node = parse(pkl_strings[3])
      expect(node.to_ruby(nil))
        .to match_pkl_object(entries: { 'foo' => 0, 'bar' => 1, 'baz' => 2 })

      node = parse(pkl_strings[4])
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            name: 'Pigeon', lifespan: 8, extinct: false
          },
          elements: [
            'wing', 'claw', 42
          ],
          entries: {
            'wing' => "Not related to \nthe _element_ \"wing\"",
            false => match_pkl_object(
              properties: { description: 'Construed object example' }
            )
          }
        )

      node = parse(pkl_strings[5])
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            bird: match_pkl_object(
              properties: {
                name: 'Pigeon', diet: 'Seeds',
                taxonomy: match_pkl_object(
                  properties: {
                    kingdom: 'Animalia', clade: 'Dinosauria',
                    order: 'Columbiformes'
                  }
                )
              }
            ),
            parrot: match_pkl_object(
              properties: {
                name: 'Parrot', diet: 'Berries',
                taxonomy: match_pkl_object(
                  properties: {
                    kingdom: 'Animalia', clade: 'Dinosauria',
                    order: 'Psittaciformes'
                  }
                )
              }
            )
          }
        )

      node = parse(pkl_strings[6])
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

      node = parse(pkl_strings[7])
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            foo_0: 0, foo_1: 1,
            bar: match_pkl_object(
              properties: { bar_0: 2, bar_1: 3 }
            )
          }
        )

      node = parse(pkl_strings[8])
      expect(node.to_ruby(nil))
        .to match_pkl_object(
          properties: {
            foo: 3,
            bar: match_pkl_object(
              properties: { foo: 5 },
              entries: { 3 => 7 }
            )
          }
        )

      node = parse(pkl_strings[9])
      node.to_ruby(nil).then do |o|
        expect(o)
          .to match_pkl_object(
            properties: { foo: 1, bar: equal(o) }
          )
      end
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string repasenting itself' do
      node = parse(pkl_strings[0])
      s = 'new Dynamic {}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[1])
      s = 'new Dynamic { 0; 1; 2 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[2])
      s = 'new Dynamic { foo = 0; bar = 1; baz = 2 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[3])
      s = 'new Dynamic { ["foo"] = 0; ["bar"] = 1; ["baz"] = 2 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[4])
      s =
        'new Dynamic { ' \
        'name = "Pigeon"; lifespan = 8; extinct = false; ' \
        '["wing"] = "Not related to \nthe _element_ \"wing\""; ' \
        '[false] { description = "Construed object example" }; ' \
        '"wing"; "claw"; 42 ' \
        '}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[5])
      s =
        'new Dynamic { ' \
        'bird { '\
        'name = "Pigeon"; diet = "Seeds"; ' \
        'taxonomy { kingdom = "Animalia"; clade = "Dinosauria"; order = "Columbiformes" } }; ' \
        'parrot { '\
        'name = "Parrot"; diet = "Berries"; ' \
        'taxonomy { kingdom = "Animalia"; clade = "Dinosauria"; order = "Psittaciformes" } } ' \
        '}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[6])
      s =
        'new Dynamic { ' \
        'foo { bar = 3; ["baz"] = 5; 1; 4 } ' \
        '}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[7])
      s =
        'new Dynamic { ' \
        'foo_0 = 0; foo_1 = 1; ' \
        'bar { bar_0 = 2; bar_1 = 3 } ' \
        '}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[8])
      s =
        'new Dynamic { ' \
        'foo = 3; bar { foo = 5; [3] = 7 } ' \
        '}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[9])
      s = 'new Dynamic { foo = 1; bar { foo = 1; bar = ? } }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s
    end
  end

  describe 'subscript operation' do
    context 'when the given key mathes an element index' do
      it 'should return the specified element' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[2]
          bar_1 = foo[1]
          bar_2 = foo[0]
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-3].value).to be_int(2)
          expect(n.properties[-2].value).to be_int(1)
          expect(n.properties[-1].value).to be_int(0)
        end
      end
    end

    context 'when the given key matches an entry key' do
      it 'should return the specified entry' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo { 1 2 3 }
          bar {
            [foo]   = 0
            [true]  = 1
            [false] = 2
            ["foo"] = 3
            [0]     = 4
          }
          baz_0 = bar[0]
          baz_1 = bar["foo"]
          baz_2 = bar[false]
          baz_3 = bar[true]
          baz_4 = bar[foo]
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-5].value).to be_int(4)
          expect(n.properties[-4].value).to be_int(3)
          expect(n.properties[-3].value).to be_int(2)
          expect(n.properties[-2].value).to be_int(1)
          expect(n.properties[-1].value).to be_int(0)
        end
      end
    end

    context 'when no elements/entries are not found' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[-1]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'-1\''

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[3]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'3\''

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar_0 = foo[0.0]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'0.0\''

        node = parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            ["foo"] = 1
            [0] = 2
          }
          bar_0 = foo[false]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'false\''

        node = parse(<<~'PKL', root: :pkl_module)
          foo {
            [true] = 0
            ["foo"] = 1
            [0] = 2
          }
          bar_0 = foo["bar"]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'"bar"\''

        node = parse(<<~'PKL', root: :pkl_module)
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

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL', root: :pkl_module)
        foo {}
        bar = -foo
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Dynamic type'

      node = parse(<<~'PKL', root: :pkl_module)
        foo {}
        bar = !foo
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Dynamic type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a {}
          b {}
        PKL
        strings << <<~'PKL'
          a { foo = 1 }
          b { foo = 1 }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar = "fizz" }
          b { foo = 1 bar = "fizz" }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar = "fizz" }
          b { bar = "fizz" foo = 1 }
        PKL
        strings << <<~'PKL'
          a { 0 1 }
          b { 0 1 }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 ["bar"] = "fizz" }
          b { ["foo"] = 1 ["bar"] = "fizz" }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 ["bar"] = "fizz" }
          b { ["bar"] = "fizz" ["foo"] = 1 }
        PKL
        strings << <<~'PKL'
          k { key = 1 }
          a { [k] = 1 }
          b { [k] = 1 }
        PKL
        strings << <<~'PKL'
          k1 { key = 1 }
          k2 { key = 1 }
          a { [k1] = 1 }
          b { [k2] = 1 }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar { baz = 2 } }
          b { foo = 1 bar { baz = 2 } }
        PKL
        strings << <<~'PKL'
          a { 0 foo = 1 ["foo"] = 2 3 bar = 4 ["bar"] = 5 }
          b { 0 foo = 1 ["foo"] = 2 3 bar = 4 ["bar"] = 5 }
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a {}
          b { foo = 2 }
        PKL
        strings << <<~'PKL'
          a { foo = 1 }
          b { foo = 2 }
        PKL
        strings << <<~'PKL'
          a { foo = 1 }
          b { bar = 1 }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar = "fizz" }
          b { foo = 1 bar = "buzz" }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar = "fizz" }
          b { foo = 1 baz = "fizz" }
        PKL
        strings << <<~'PKL'
          a { foo = 1 bar = "fizz" baz = "buzz" }
          b { foo = 1 bar = "fizz" }
        PKL
        strings << <<~'PKL'
          a {}
          b { 2 }
        PKL
        strings << <<~'PKL'
          a { 0 1 }
          b { 2 3 }
        PKL
        strings << <<~'PKL'
          a { 0 1 }
          b { 1 0 }
        PKL
        strings << <<~'PKL'
          a { 0 1 }
          b { 0 }
        PKL
        strings << <<~'PKL'
          a { 0 1 }
          b { 0 1.0 }
        PKL
        strings << <<~'PKL'
          a {}
          b { ["foo"] = 2 }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 }
          b { ["foo"] = 2 }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 }
          b { ["bar"] = 1 }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 ["bar"] = "fizz" }
          b { ["foo"] = 1 ["bar"] = "buzz" }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 ["bar"] = "fizz" }
          b { ["foo"] = 1 ["baz"] = "fizz" }
        PKL
        strings << <<~'PKL'
          a { ["foo"] = 1 ["bar"] = "fizz" ["baz"] = "buzz" }
          b { ["foo"] = 1 ["bar"] = "fizz" }
        PKL
        strings << <<~'PKL'
          k { key = 1 }
          a { [k] = 1 }
          b { [k] = 2 }
        PKL
        strings << <<~'PKL'
          k1 { key = 1 }
          k2 { key = 2 }
          a { [k1] = 1 }
          b { [k2] = 1 }
        PKL
        strings << <<~'PKL'
          foo { foo = 1 }
          bar { bar = 1 }
          a { [foo] = 1 }
          b { [bar] = 1 }
        PKL
        strings << <<~'PKL'
          a {}
          b = true
        PKL
        strings << <<~'PKL'
          a {}
          b = 1
        PKL
        strings << <<~'PKL'
          a {}
          b = 1.0
        PKL
        strings << <<~'PKL'
          a {}
          b = "foo"
        PKL
        strings << <<~'PKL'
          a {}
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a {}
          b = new Listing {}
        PKL
      end

      it 'should execlute the given operation' do
        pkl_match_strings.each do |pkl|
          node = parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a == b
            d = a != b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-2].value).to be_boolean(true)
            expect(n.properties[-1].value).to be_boolean(false)
          end
        end

        pkl_unmatch_strings.each do |pkl|
          node = parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a != b
            d = a == b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-2].value).to be_boolean(true)
            expect(n.properties[-1].value).to be_boolean(false)
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
          node = parse(<<~PKL, root: :pkl_module)
            foo {}
            bar {}
            baz = foo #{op} bar
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Dynamic type"
        end
      end
    end
  end

  describe 'builtin method' do
    describe 'length' do
      it 'should return the number of the elements in this object' do
        node = parse(<<~'PKL', root: :pkl_module)
          obj1 = new Dynamic {
            prop1 = "prop1"
            prop2 = "prop2"
            ["name"] = "Pigeon"
            ["age"] = 42
            "one"
            "two"
          }
          obj2 = (obj1) { "three"; "four" }{ x = 1 }{ "five" }{}
          obj3 = (obj1) { [0] = "one one"; [1] = "two two" }
          a = obj1.length()
          b = obj2.length()
          c = obj3.length()
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(2)
          expect(b.value).to be_int(5)
          expect(c.value).to be_int(2)
        end

        node = parse(<<~'PKL', root: :pkl_module)
          a = new Dynamic {}.length()
          b = new Dynamic { name = "Pigeon" }.length()
          c = new Dynamic { ["name"] = "Pigeon" }.length()
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(0)
          expect(b.value).to be_int(0)
          expect(c.value).to be_int(0)
        end
      end
    end

    describe 'hasProperty' do
      it 'should tell this object has a property with the given name' do
        node = parse(<<~'PKL', root: :pkl_module)
          obj1 = new Dynamic {
            name = "Pigeon"
            age = 42
          }
          obj2 = (obj1) {
            age = 43
            nostalgia = true
          }
          a = obj1.hasProperty("name")
          b = obj1.hasProperty("na" + "me")
          c = obj1.hasProperty("age")
          d = obj1.hasProperty("nostalgia")
          e = obj1.hasProperty("other")
          f = obj2.hasProperty("name")
          g = obj2.hasProperty("age")
          h = obj2.hasProperty("nostalgia")
          i = obj2.hasProperty("other")
        PKL
        node.evaluate(nil).properties[-9..].then do |(a, b, c, d, e, f, g, h, i)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(false)
          expect(e.value).to be_boolean(false)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(true)
          expect(h.value).to be_boolean(true)
          expect(i.value).to be_boolean(false)
        end
      end
    end

    describe 'getProperty' do
      it 'should return the value of the property with the given name' do
        pkl = <<~'PKL'
            obj1 = new Dynamic {
              name = "Pig" + "eon"
              age = 42
            }
            obj2 = (obj1) {
              age = 43
              nostalgia = true
            }
            a = obj1.getProperty("name")
            b = obj1.getProperty("na" + "me")
            c = obj1.getProperty("age")
            d = obj2.getProperty("name")
            e = obj2.getProperty("age")
            f = obj2.getProperty("nostalgia")
        PKL
        node = parse(pkl, root: :pkl_module)
        node.evaluate(nil).properties[-6..].then do |(a, b, c, d, e, f)|
          expect(a.value).to be_evaluated_string('Pigeon')
          expect(b.value).to be_evaluated_string('Pigeon')
          expect(c.value).to be_int(42)
          expect(d.value).to be_evaluated_string('Pigeon')
          expect(e.value).to be_int(43)
          expect(f.value).to be_boolean(true)
        end
      end

      context 'when there are no properties with the given name' do
        it 'should raise EvaluationError' do
          pkl = <<~'PKL'
            obj1 = new Dynamic {
              name = "Pigeon"
              age = 42
            }
            obj2 = (obj1) {
              age = 43
              nostalgia = true
            }
            a = obj1.getProperty("nostalgia")
          PKL
          node = parse(pkl, root: :pkl_module)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'cannot find property \'nostalgia\''

          pkl = <<~'PKL'
            obj1 = new Dynamic {
              name = "Pigeon"
              age = 42
            }
            obj2 = (obj1) {
              age = 43
              nostalgia = true
            }
            a = obj2.getProperty("other")
          PKL
          node = parse(pkl, root: :pkl_module)
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'cannot find property \'other\''
        end
      end
    end

    describe 'getPropertyOrNull' do
      it 'should return the value of the property with the given name' do
        pkl = <<~'PKL'
            obj1 = new Dynamic {
              name = "Pig" + "eon"
              age = 42
            }
            obj2 = (obj1) {
              age = 43
              nostalgia = true
            }
            a = obj1.getPropertyOrNull("name")
            b = obj1.getPropertyOrNull("na" + "me")
            c = obj1.getPropertyOrNull("age")
            d = obj2.getPropertyOrNull("name")
            e = obj2.getPropertyOrNull("age")
            f = obj2.getPropertyOrNull("nostalgia")
        PKL
        node = parse(pkl, root: :pkl_module)
        node.evaluate(nil).properties[-6..].then do |(a, b, c, d, e, f)|
          expect(a.value).to be_evaluated_string('Pigeon')
          expect(b.value).to be_evaluated_string('Pigeon')
          expect(c.value).to be_int(42)
          expect(d.value).to be_evaluated_string('Pigeon')
          expect(e.value).to be_int(43)
          expect(f.value).to be_boolean(true)
        end
      end

      context 'when there are no properties with the given name' do
        it 'should return a null value' do
          pkl = <<~'PKL'
            obj1 = new Dynamic {
              name = "Pigeon"
              age = 42
            }
            obj2 = (obj1) {
              age = 43
              nostalgia = true
            }
            a = obj1.getPropertyOrNull("nostalgia")
            b = obj2.getPropertyOrNull("other")
          PKL
          node = parse(pkl, root: :pkl_module)
          node.evaluate(nil).properties[-2..].then do |(a, b)|
            expect(a.value).to be_null
            expect(b.value).to be_null
          end
        end
      end
    end
  end
end
