# frozen_string_literal: true

RSpec.describe RuPkl::Node::Mapping do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      new Mapping {}
    PKL
    strings << <<~'PKL'
      new Mapping { ["foo"] = 1 ["bar"] = 2 ["baz"] = 1 + 2 }
    PKL
    strings << <<~'PKL'
      new Mapping {
        ["foo"] = 1 ["bar"] = 2
      }{
        ["baz"] = 3
      }
    PKL
    strings << <<~'PKL'
      {
        res1 = new Mapping {
          ["foo"] = 1 ["bar"] = 2
        }
        res2 = (res1) {
          ["foo"] = 2
        }{
          ["baz"] = 1 + 2
        }
      }
    PKL
    strings << <<~'PKL'
      new Mapping {
        [0+1] = new Mapping {
          ["a"] = new Mapping {
            ["x"] = 0 + 1
          }
          ["b"] = new Mapping {
            ["y"] = 1 + 1
          }
        }
        [1+1] = new Mapping {
          ["c"] = new Mapping {
            ["z"] = 2 + 1
          }
        }
      }
    PKL
    strings << <<~'PKL'
      new Mapping {
        ["foo"] = 0
        ["bar"] = 1
        ["baz"] = this
      }
    PKL
  end

  def parse(string, root: :expression)
    parser.parse(string.chomp, root: root)
  end

  specify 'entry members are only allowed' do
    node = parse(<<~'PKL')
      new Mapping {
        foo = 1
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Mapping' cannot have a property"

    node = parse(<<~'PKL', root: :pkl_module)
      foo = new Mapping {}
      bar = (foo) { bar = 1 }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Mapping' cannot have a property"

    node = parse(<<~'PKL')
      new Mapping {
        1 2 3
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Mapping' cannot have an element"

    node = parse(<<~'PKL', root: :pkl_module)
      foo = new Mapping {}
      bar = (foo) { 1 2 3 }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Mapping' cannot have an element"
  end

  describe '#evaluate' do
    it 'should return a Mapping object containing members eagerly evaluated' do
      node = parse(pkl_strings[0])
      expect(node.evaluate(nil)).to be_mapping

      node = parse(pkl_strings[1])
      expect(node.evaluate(nil)).to (
        be_mapping do |m|
          m['foo'] = 1; m['bar'] = 2; m['baz'] = 3
        end
      )

      node = parse(pkl_strings[2])
      expect(node.evaluate(nil)).to (
        be_mapping do |m|
          m['foo'] = 1; m['bar'] = 2; m['baz'] = 3
        end
      )

      node = parse(pkl_strings[3], root: :object)
      node.evaluate(nil).properties[-1].then do |n|
        expect(n.value).to (
          be_mapping do |m|
            m['foo'] = 2; m['bar'] = 2; m['baz'] = 3
          end
        )
      end

      node = parse(pkl_strings[4])
      expect(node.evaluate(nil)).to (
        be_mapping do |m1|
          m1[1] = mapping do |m2|
            m2['a'] = mapping do |m3|
              m3['x'] = 1
            end
            m2['b'] = mapping do |m3|
              m3['y'] = 2
            end
          end
          m1[2] = mapping do |m2|
            m2['c'] = mapping do |m3|
              m3['z'] = 3
            end
          end
        end
      )

      node = parse(pkl_strings[5])
      node.evaluate(nil).then do |n|
        expect(n).to (
          be_mapping do |m|
            m['foo'] = 0
            m['bar'] = 1
            m['baz'] = equal(n)
          end
        )
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a PklObject object containing evaluated members' do
      node = parse(pkl_strings[0])
      expect(node.to_ruby(nil)).to match_pkl_object

      node = parse(pkl_strings[1])
      expect(node.to_ruby(nil)).to match_pkl_object(
        entries: {
          'foo' => 1, 'bar' => 2, 'baz' => 3
        }
      )

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil)).to match_pkl_object(
        entries: {
          'foo' => 1, 'bar' => 2, 'baz' => 3
        }
      )

      node = parse(pkl_strings[3], root: :object)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          res1: match_pkl_object(
            entries: { 'foo' => 1, 'bar' => 2 }
          ),
          res2: match_pkl_object(
            entries: { 'foo' => 2, 'bar' => 2, 'baz' => 3 }
          )
        }
      )

      node = parse(pkl_strings[4])
      expect(node.to_ruby(nil)).to match_pkl_object(
        entries: {
          1 => match_pkl_object(
            entries: {
              'a' => match_pkl_object(entries: { 'x' => 1 }),
              'b' => match_pkl_object(entries: { 'y' => 2 })
            }
          ),
          2 => match_pkl_object(
            entries: {
              'c' => match_pkl_object(entries: { 'z' => 3 })
            }
          )
        }
      )

      node = parse(pkl_strings[5])
      node.to_ruby(nil).then do |o|
        expect(o).to match_pkl_object(
          entries: {
            'foo' => 0, 'bar' => 1, 'baz' => equal(o)
          }
        )
      end
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string repasenting itself' do
      node = parse(pkl_strings[0])
      s = 'new Mapping {}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[1])
      s = 'new Mapping { ["foo"] = 1; ["bar"] = 2; ["baz"] = 3 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[2])
      s = 'new Mapping { ["foo"] = 1; ["bar"] = 2; ["baz"] = 3 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[3], root: :object)
      s = 'new Mapping { ["foo"] = 2; ["bar"] = 2; ["baz"] = 3 }'
      node.resolve_structure(nil).properties[-1].then do |n|
        expect(n.value.to_string(nil)).to eq s
        expect(n.value.to_pkl_string(nil)).to eq s
      end

      node = parse(pkl_strings[4])
      s = [
        'new Mapping { ',
          '[1] = new Mapping { ',
            '["a"] = new Mapping { ',
              '["x"] = 1',
            ' }; ',
            '["b"] = new Mapping { ',
              '["y"] = 2',
            ' }',
          ' }; ',
          '[2] = new Mapping { ',
            '["c"] = new Mapping { ',
              '["z"] = 3',
            ' }',
          ' }',
        ' }'
      ].join
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[5])
      s = [
        'new Mapping { ',
          '["foo"] = 0; ["bar"] = 1; ["baz"] = ',
            'new Mapping { ["foo"] = 0; ["bar"] = 1; ["baz"] = ? } ',
        '}'
      ].join
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s
    end
  end

  describe 'subscript operation' do
    context 'when the given key matches an entry key' do
      it 'should return the specified entry' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo = new Dynamic { 1 2 3 }
          bar = new Mapping {
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

    context 'when no entrie is found' do
      it 'should raise EvaluationError' do
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
      node = parse(<<~'PKL')
        -(new Mapping{})
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Mapping type'

      node = parse(<<~'PKL')
        !(new Mapping{})
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Mapping type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = new Mapping {}
          b = new Mapping {}
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
          b = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
          b = new Mapping { ["bar"] = "fizz" ["foo"] = 1 }
        PKL
        strings << <<~'PKL'
          o = new Mapping { ["foo"] = 1 }
          a = new Mapping { ["bar"] = o }
          b = new Mapping { ["bar"] = o }
        PKL
        strings << <<~'PKL'
          o1 = new Mapping { ["foo"] = 1 }
          o2 = new Mapping { ["foo"] = 1 }
          a = new Mapping { ["bar"] = o1 }
          b = new Mapping { ["bar"] = o2 }
        PKL
        strings << <<~'PKL'
          k = new Mapping { ["key"] = 1 }
          a = new Mapping { [k] = 1 }
          b = new Mapping { [k] = 1 }
        PKL
        strings << <<~'PKL'
          k1 = new Mapping { ["key"] = 1 }
          k2 = new Mapping { ["key"] = 1 }
          a = new Mapping { [k1] = 1 }
          b = new Mapping { [k2] = 1 }
        PKL
        strings << <<~'PKL'
          o = new Mapping { ["foo"] = 1 }
          a = new Mapping { [o] = 1 }
          b = new Mapping { [o] = 1 }
        PKL
        strings << <<~'PKL'
          o1 = new Mapping { ["foo"] = 1 }
          o2 = new Mapping { ["foo"] = 1 }
          a = new Mapping { [o1] = 1 }
          b = new Mapping { [o2] = 1 }
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = new Mapping {}
          b = new Mapping { ["foo"] = 2 }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 }
          b = new Mapping { ["foo"] = 2 }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 }
          b = new Mapping { ["bar"] = 1 }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
          b = new Mapping { ["foo"] = 1 ["bar"] = "buzz" }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
          b = new Mapping { ["foo"] = 1 ["baz"] = "fizz" }
        PKL
        strings << <<~'PKL'
          a = new Mapping { ["foo"] = 1 ["bar"] = "fizz" ["baz"] = "buzz" }
          b = new Mapping { ["foo"] = 1 ["bar"] = "fizz" }
        PKL
        strings << <<~'PKL'
          o = new Mapping { ["foo"] = 1 }
          a = new Mapping { ["bar"] = o }
          b = new Mapping { ["baz"] = o }
        PKL
        strings << <<~'PKL'
          o1 = new Mapping { ["foo"] = 1 }
          o2 = new Mapping { ["foo"] = 2 }
          a = new Mapping { ["bar"] = o1 }
          b = new Mapping { ["bar"] = o2 }
        PKL
        strings << <<~'PKL'
          k = new Mapping { ["key"] = 1 }
          a = new Mapping { [k] = 1 }
          b = new Mapping { [k] = 2 }
        PKL
        strings << <<~'PKL'
          k1 = new Mapping { ["key"] = 1 }
          k2 = new Mapping { ["key"] = 2 }
          a = new Mapping { [k1] = 1 }
          b = new Mapping { [k2] = 1 }
        PKL
        strings << <<~'PKL'
          o = new Mapping { ["foo"] = 1 }
          a = new Mapping { [o] = 1 }
          b = new Mapping { [o] = 2 }
        PKL
        strings << <<~'PKL'
          o1 = new Mapping { ["foo"] = 1 }
          o2 = new Mapping { ["foo"] = 2 }
          a = new Mapping { [o1] = 1 }
          b = new Mapping { [o2] = 1 }
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = true
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = 1
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = "foo"
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = new Mapping {}
          b = new Listing {}
        PKL
      end

      it 'should execute the given operation' do
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
          node = parser.parse(<<~PKL, root: :pkl_module)
            foo = new Mapping {}
            bar = new Mapping {}
            baz = foo #{op} bar
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Mapping type"
        end
      end
    end
  end

  describe 'builtin property/method' do
    let(:mapping) do
      <<~'PKL'
        obj1 = new Mapping {
          ["Pigeon"] { name = "Pigeon" }
          ["Parrot"] { name = "Parrot"; age = 24 }
        }
        obj2 = (obj1) {
          ["Pigeon"] { name = "Piggy" }
          ["Barn Owl"] { name = "Barn Owl"; age = 84 }
        }
        obj3 = new Mapping {}
      PKL
    end

    describe 'isEmpty' do
      it 'should tell if this mapping is empty' do
        node = parse(<<~PKL, root: :pkl_module)
          #{mapping}
          a = obj1.isEmpty
          b = obj2.isEmpty
          c = obj3.isEmpty
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_boolean(false)
          expect(b.value).to be_boolean(false)
          expect(c.value).to be_boolean(true)
        end
      end
    end

    describe 'length' do
      it 'should return the number of entries in this mapping' do
        node = parse(<<~PKL, root: :pkl_module)
          #{mapping}
          a = obj1.length
          b = obj2.length
          c = obj3.length
        PKL
        node.evaluate(nil).properties[-3..].then do |(a, b, c)|
          expect(a.value).to be_int(2)
          expect(b.value).to be_int(3)
          expect(c.value).to be_int(0)
        end
      end
    end

    describe 'containsKey' do
      it 'should tell if this mapping contains the given key' do
        node = parse(<<~PKL, root: :pkl_module)
          #{mapping}
          a = obj1.containsKey("Pigeon")
          b = obj1.containsKey("Parrot")
          c = obj1.containsKey("Barn Owl")
          d = obj1.containsKey("Other")
          e = obj2.containsKey("Pigeon")
          f = obj2.containsKey("Parrot")
          g = obj2.containsKey("Barn Owl")
          h = obj2.containsKey("Other")
          i = obj3.containsKey("Pigeon")
          j = obj3.containsKey("Other")
        PKL
        node.evaluate(nil).properties[-10..].then do |(a, b, c, d, e, f, g, h, i, j)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(false)
          expect(d.value).to be_boolean(false)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(true)
          expect(h.value).to be_boolean(false)
          expect(i.value).to be_boolean(false)
          expect(j.value).to be_boolean(false)
        end
      end
    end

    describe 'getOrNull' do
      it 'should return the value associated with the given key' do
        node = parse(<<~PKL, root: :pkl_module)
          #{mapping}
          a = obj1.getOrNull("Pigeon")
          b = obj1.getOrNull("Parrot")
          c = obj2.getOrNull("Pigeon")
          d = obj2.getOrNull("Parrot")
          e = obj2.getOrNull("Barn Owl")
        PKL
        node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
          expect(a.value).to (be_dynamic { |o| o.property :name, 'Pigeon' })
          expect(b.value).to (be_dynamic { |o| o.property :name, 'Parrot'; o.property :age, 24 })
          expect(c.value).to (be_dynamic { |o| o.property :name, 'Piggy' })
          expect(d.value).to (be_dynamic { |o| o.property :name, 'Parrot'; o.property :age, 24 })
          expect(e.value).to (be_dynamic { |o| o.property :name, 'Barn Owl'; o.property :age, 84 })
        end
      end

      context 'when this mapping does not contain the given key' do
        it 'should return a null value' do
          node = parse(<<~PKL, root: :pkl_module)
            #{mapping}
            a = obj1.getOrNull("Barn Owl")
            b = obj1.getOrNull("Other")
            c = obj2.getOrNull("Other")
            d = obj3.getOrNull("Parrot")
            e = obj3.getOrNull("Other")
          PKL
          node.evaluate(nil).properties[-5..].then do |(a, b, c, d, e)|
            expect(a.value).to be_null
            expect(b.value).to be_null
            expect(c.value).to be_null
            expect(d.value).to be_null
            expect(e.value).to be_null
          end
        end
      end
    end
  end
end
