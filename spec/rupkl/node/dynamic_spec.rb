# frozen_string_literal: true

RSpec.describe RuPkl::Node::Dynamic do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#to_ruby' do
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
    end

    def parse(string)
      parser.parse(string.chomp, root: :object)
    end

    it 'should return a Dynamic object contating evaluated members' do
      node = parse(pkl_strings[0])
      expect(node.to_ruby(nil)).to match_dynamic

      node = parse(pkl_strings[1])
      expect(node.to_ruby(nil))
        .to match_dynamic(elements: [0, 1, 2])

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil))
        .to match_dynamic(properties: { foo: 1, bar: 2 })

      node = parse(pkl_strings[3])
      expect(node.to_ruby(nil))
        .to match_dynamic(entries: { 'foo' => 1, 'bar' => 2 })

      node = parse(pkl_strings[4])
      expect(node.to_ruby(nil))
        .to match_dynamic(
          properties: {
            name: 'Pigeon', lifespan: 8, extinct: false
          },
          elements: [
            'wing', 'claw', 42
          ],
          entries: {
            'wing' => 'Not related to the _element_ "wing"',
            false => match_dynamic(
              properties: { description: 'Construed object example' }
            )
          }
        )

      node = parse(pkl_strings[5])
      expect(node.to_ruby(nil))
        .to match_dynamic(
          properties: {
            foo: match_dynamic(
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
          expect(n.properties[-5].value).to be_integer(4)
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
          foo { 0 1 2 }
          bar_0 = foo[0.0]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find key \'0.0\''

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

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo {}
        bar = -foo
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Dynamic type'

      node = parser.parse(<<~'PKL', root: :pkl_module)
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
      end

      it 'should execlute the given operation' do
        pkl_match_strings.each do |pkl|
          node = parser.parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a == b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-1].value).to be_boolean(true)
          end

          node = parser.parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a != b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-1].value).to be_boolean(false)
          end
        end

        pkl_unmatch_strings.each do |pkl|
          node = parser.parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a == b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-1].value).to be_boolean(false)
          end

          node = parser.parse(<<~PKL, root: :pkl_module)
            #{pkl}
            c = a != b
          PKL
          node.evaluate(nil).then do |n|
            expect(n.properties[-1].value).to be_boolean(true)
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
          node = parser.parse(<<~PKL, root: :pkl_module)
            foo {}
            bar {}
            baz = foo #{op} bar
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Dynamic type"
        end
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        ['==', '!='].each do |op|
          node = parser.parse(<<~PKL, root: :pkl_module)
            foo {}
            bar = foo #{op} true
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

          node = parser.parse(<<~PKL, root: :pkl_module)
            foo {}
            bar = foo #{op} "foo"
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

          node = parser.parse(<<~PKL, root: :pkl_module)
            foo {}
            bar = foo #{op} 1
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Integer is given for operator '#{op}'"

          node = parser.parse(<<~PKL, root: :pkl_module)
            foo {}
            bar = foo #{op} 1.0
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"
        end
      end
    end
  end
end
