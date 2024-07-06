# frozen_string_literal: true

RSpec.describe RuPkl::Node::Listing do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      new Listing {}
    PKL
    strings << <<~'PKL'
      new Listing { 1 2 1 + 2 }
    PKL
    strings << <<~'PKL'
      new Listing {
        1 2
      } {
        3
      }
    PKL
    strings << <<~'PKL'
      {
        res1 = new Listing { 1 2 }
        res2 = (res1) {
          [0] = 2
        }{
          1 + 2
        }
      }
    PKL
    strings << <<~'PKL'
      new Listing {
        new Listing {
          "one"
        }
        new Listing {
          "two"
          "th" + "ree"
        }
        new Mapping {
          ["four"] = 4
        }
      }
    PKL
    strings << <<~'PKL'
      {
        birds = new Listing {
          new { name = "Pigeon"; diet = "Seeds" }
          new { name = "Parrot"; diet = "Berries" }
        }
        birds2 = (birds) {
          new { name = "Barn owl"; diet = "Mice" }
          [0] { diet = "Worms" }
          [1] = new { name = "Albatross"; diet = "Fish" }
        }
      }
    PKL
    strings << <<~'PKL'
      new Listing { 0 1 this }
    PKL
  end

  def parse(string, root: :expression)
    parser.parse(string.chomp, root: root)
  end

  specify 'element members are only allowed' do
    node = parse(<<~'PKL')
      new Listing {
        foo = 1
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Listing' cannot have a property"

    node = parse(<<~'PKL', root: :pkl_module)
      foo = new Listing {}
      bar = (foo) { bar = 1 }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Listing' cannot have a property"

    node = parse(<<~'PKL')
      new Listing {
        ["foo"] = 1
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Listing' cannot have an entry"

    node = parse(<<~'PKL', root: :pkl_module)
      foo = new Listing {}
      bar = (foo) { ["bar"] = 1 }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error "'Listing' cannot have an entry"
  end

  describe '#evaluate' do
    it 'should return a Listing object containing members eagerly evaluated' do
      node = parse(pkl_strings[0])
      expect(node.evaluate(nil)).to be_listing

      node = parse(pkl_strings[1])
      expect(node.evaluate(nil)).to (
        be_listing do |l|
          l <<1; l << 2; l << 3
        end
      )

      node = parse(pkl_strings[2])
      expect(node.evaluate(nil)).to (
        be_listing do |l|
          l <<1; l << 2; l << 3
        end
      )

      node = parse(pkl_strings[3], root: :object)
      node.evaluate(nil).properties[-1].then do |n|
        expect(n.value).to (
          be_listing do |l|
            l <<2; l << 2; l << 3
          end
        )
      end

      node = parse(pkl_strings[4])
      expect(node.evaluate(nil)).to (
        be_listing do |l1|
          l1 << (listing { |l2| l2 << 'one' })
          l1 << (listing { |l2| l2 << 'two'; l2 << 'three' })
          l1 << (mapping { |m2| m2['four'] = 4 })
        end
      )

      node = parse(pkl_strings[5], root: :object)
      node.evaluate(nil).properties[-2..-1].then do |(n1, n2)|
        expect(n1.value).to (
          be_listing do |l1|
            l1 << (dynamic { |d2| d2.property :name, 'Pigeon'; d2.property :diet, 'Seeds' })
            l1 << (dynamic { |d2| d2.property :name, 'Parrot'; d2.property :diet, 'Berries' })
          end
        )
        expect(n2.value).to (
          be_listing do |l1|
            l1 << (dynamic { |d2| d2.property :name, 'Pigeon'; d2.property :diet, 'Worms' })
            l1 << (dynamic { |d2| d2.property :name, 'Albatross'; d2.property :diet, 'Fish' })
            l1 << (dynamic { |d2| d2.property :name, 'Barn owl'; d2.property :diet, 'Mice' })
          end
        )
      end

      node = parse(pkl_strings[6])
      node.evaluate(nil).then do |n|
        expect(n).to (
          be_listing { |l| l << 0; l << 1; l << equal(n) }
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
        elements: [1, 2, 3]
      )

      node = parse(pkl_strings[2])
      expect(node.to_ruby(nil)).to match_pkl_object(
        elements: [1, 2, 3]
      )

      node = parse(pkl_strings[3], root: :object)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          res1: match_pkl_object(
            elements: [1, 2]
          ),
          res2: match_pkl_object(
            elements: [2, 2, 3]
          )
        }
      )

      node = parse(pkl_strings[4])
      expect(node.to_ruby(nil)).to match_pkl_object(
        elements: [
          match_pkl_object(
            elements: ['one']
          ),
          match_pkl_object(
            elements: ['two', 'three']
          ),
          match_pkl_object(
            entries: { 'four' => 4 }
          )
        ]
      )

      node = parse(pkl_strings[5], root: :object)
      expect(node.to_ruby(nil)).to match_pkl_object(
        properties: {
          birds: match_pkl_object(
            elements: [
              match_pkl_object(properties: { name: 'Pigeon', diet: 'Seeds' }),
              match_pkl_object(properties: { name: 'Parrot', diet: 'Berries' })
            ]
          ),
          birds2: match_pkl_object(
            elements: [
              match_pkl_object(properties: { name: 'Pigeon', diet: 'Worms' }),
              match_pkl_object(properties: { name: 'Albatross', diet: 'Fish' }),
              match_pkl_object(properties: { name: 'Barn owl', diet: 'Mice' })
            ]
          )
        }
      )

      node = parse(pkl_strings[6])
      node.to_ruby(nil).then do |o|
        expect(o).to match_pkl_object(
          elements: [0, 1, equal(o)]
        )
      end
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      node = parse(pkl_strings[0])
      s = 'new Listing {}'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[1])
      s = 'new Listing { 1; 2; 3 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[2])
      s = 'new Listing { 1; 2; 3 }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[3], root: :object)
      s = [
        'new Dynamic { ',
          'res1 = new Listing { 1; 2 }; ',
          'res2 = new Listing { 2; 2; 3 } ',
        '}'
      ].join
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[4])
      s = [
        'new Listing { ',
          'new Listing { "one" }; ',
          'new Listing { "two"; "three" }; ',
          'new Mapping { ["four"] = 4 } ',
        '}'
      ].join
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[5], root: :object)
      s = [
        'new Dynamic { ',
          'birds = new Listing { ',
            'new Dynamic { name = "Pigeon"; diet = "Seeds" }; ',
            'new Dynamic { name = "Parrot"; diet = "Berries" } ',
          '}; ',
          'birds2 = new Listing { ',
            'new Dynamic { name = "Pigeon"; diet = "Worms" }; ',
            'new Dynamic { name = "Albatross"; diet = "Fish" }; ',
            'new Dynamic { name = "Barn owl"; diet = "Mice" } ',
          '} ',
        '}'
      ].join
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s

      node = parse(pkl_strings[6])
      s = 'new Listing { 0; 1; new Listing { 0; 1; ? } }'
      expect(node.to_string(nil)).to eq s
      expect(node.to_pkl_string(nil)).to eq s
    end
  end

  describe 'subscript operation' do
    context 'when the given index matches an element index' do
      it 'should return the specified element' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo = new Listing {
            new Listing {
              "one"
            }
            new Listing {
              "two"
              "th" + "ree"
            }
          }
          bar_0     = foo[0]
          bar_0_0   = foo[0][0]
          bar_1     = foo[1]
          bar_1_0   = foo[1][0]
          bar_1_1   = foo[1][1]
        PKL
        node.evaluate(nil).then do |n|
          expect(n.properties[-5].value).to (be_listing { |l| l << 'one' })
          expect(n.properties[-4].value).to be_evaluated_string('one')
          expect(n.properties[-3].value).to (be_listing { |l| l << 'two'; l << 'three' })
          expect(n.properties[-2].value).to be_evaluated_string('two')
          expect(n.properties[-1].value).to be_evaluated_string('three')
        end
      end
    end

    context 'when no element is found' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar = foo[-1]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '-1'"

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar = foo[3]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '3'"

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar = foo[1.0]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '1.0'"

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar = foo["0"]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key '\"0\"'"

        node = parse(<<~'PKL', root: :pkl_module)
          foo { 0 1 2 }
          bar = foo[true]
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "cannot find key 'true'"
      end
    end
  end

  describe 'unary operation' do
    specify 'any unary operations are not defined' do
      node = parse(<<~'PKL')
        -(new Listing{})
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'-\' is not defined for Listing type'

      node = parse(<<~'PKL')
        !(new Listing{})
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'operator \'!\' is not defined for Listing type'
    end
  end

  describe 'binary operation' do
    context 'when defined operator and valid operand are given' do
      let(:pkl_match_strings) do
        strings = []
        strings << <<~'PKL'
          a = new Listing {}
          b = new Listing {}
        PKL
        strings << <<~'PKL'
          a = new Listing { 0 1 }
          b = new Listing { 0 1 }
        PKL
        strings << <<~'PKL'
          o1 = new Listing { 0 1 }
          o2 = new Listing { 2 3 }
          a = new Listing { o1 o2 }
          b = new Listing { o1 o2 }
        PKL
        strings << <<~'PKL'
          o1 = new Listing { 0 1 }
          o2 = new Listing { 0 1 }
          a = new Listing { o1 }
          b = new Listing { o2 }
        PKL
      end

      let(:pkl_unmatch_strings) do
        strings = []
        strings << <<~'PKL'
          a = new Listing {}
          b = new Listing { 0 }
        PKL
        strings << <<~'PKL'
          a = new Listing { 0 }
          b = new Listing { 1 }
        PKL
        strings << <<~'PKL'
          a = new Listing { 0 }
          b = new Listing { 0 1 }
        PKL
        strings << <<~'PKL'
          a = new Listing { 0 1 }
          b = new Listing { 1 0 }
        PKL
        strings << <<~'PKL'
          o1 = new Listing { 0 1 }
          o2 = new Listing { 2 3 }
          a = new Listing { o1 }
          b = new Listing { o2 }
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = true
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = 1
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = 1.0
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = "foo"
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = new Dynamic {}
        PKL
        strings << <<~'PKL'
          a = new Listing {}
          b = new Mapping {}
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
            foo = new Listing {}
            bar = new Listing {}
            baz = foo #{op} bar
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error "operator '#{op}' is not defined for Listing type"
        end
      end
    end
  end

  describe 'builtin property/method' do
    let(:listing) do
      <<~'PKL'
        obj0 = new Listing {
          new { name = "Pigeon" }
          new { name = "Barn Owl" }
          new { name = "Parrot" }
        }
        obj1 = (obj0) {
          new { name = "Albatross" }
          new { name = "Elf Owl" }
        }
        obj2 = (obj0) {
          new { name = "Albatross" }
          new { name = "Parrot" }
          new { name = "Elf Owl" }
        }
        obj3 = new Listing {}
      PKL
    end

    describe 'length' do
      it 'should return the number of elements in this listing' do
        node = parse(<<~PKL, root: :pkl_module)
          #{listing}
          a = obj0.length
          b = obj1.length
          c = obj2.length
          d = obj3.length
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_int(3)
          expect(b.value).to be_int(5)
          expect(c.value).to be_int(6)
          expect(d.value).to be_int(0)
        end
      end
    end

    describe 'isEmpty' do
      it 'should tell if this listing is empty' do
        node = parse(<<~PKL, root: :pkl_module)
          #{listing}
          a = obj0.isEmpty
          b = obj1.isEmpty
          c = obj2.isEmpty
          d = obj3.isEmpty
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_boolean(false)
          expect(b.value).to be_boolean(false)
          expect(c.value).to be_boolean(false)
          expect(d.value).to be_boolean(true)
        end
      end
    end

    describe 'isDistinct' do
      it 'should tell if this listing has no duplicate elements' do
        node = parse(<<~PKL, root: :pkl_module)
          #{listing}
          a = obj0.isDistinct
          b = obj1.isDistinct
          c = obj2.isDistinct
          d = obj3.isDistinct
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(false)
          expect(d.value).to be_boolean(true)
        end
      end
    end

    describe 'distinct' do
      it 'should remove duplicate elements from this listing' do
        node = parse(<<~PKL, root: :pkl_module)
          #{listing}
          a = obj0.distinct
          b = obj1.distinct
          c = obj2.distinct
          d = obj3.distinct
        PKL
        node.evaluate(nil).properties[-4..].then do |(a, b, c, d)|
          expect(a.value).to (be_listing do |l|
            l << dynamic { |d| d.property :name, 'Pigeon' }
            l << dynamic { |d| d.property :name, 'Barn Owl' }
            l << dynamic { |d| d.property :name, 'Parrot' }
          end)

          expect(b.value).to (be_listing do |l|
            l << dynamic { |d| d.property :name, 'Pigeon' }
            l << dynamic { |d| d.property :name, 'Barn Owl' }
            l << dynamic { |d| d.property :name, 'Parrot' }
            l << dynamic { |d| d.property :name, 'Albatross' }
            l << dynamic { |d| d.property :name, 'Elf Owl' }
          end)

          expect(c.value).to (be_listing do |l|
            l << dynamic { |d| d.property :name, 'Pigeon' }
            l << dynamic { |d| d.property :name, 'Barn Owl' }
            l << dynamic { |d| d.property :name, 'Parrot' }
            l << dynamic { |d| d.property :name, 'Albatross' }
            l << dynamic { |d| d.property :name, 'Elf Owl' }
          end)

          expect(d.value).to be_listing
        end
      end
    end

    describe 'join' do
      it 'should Convert the elements of this listing to strings and concatenate them inserting separator between elements' do
        node = parse(<<~'PKL', root: :pkl_module)
          obj0 = new Listing {}
          obj1 = new Listing { 1; 2; 3 }
          obj2 = new Listing { "Pigeon"; "Barn Owl"; "Parrot" }
          obj3 = (obj2) { "Albatross"; "Elf Owl" }
          a = obj0.join("")
          b = obj1.join("")
          c = obj1.join(", ")
          d = obj2.join("")
          e = obj2.join("---")
          f = obj3.join("")
          g = obj3.join("\n")
        PKL
        node.evaluate(nil).properties[-7..].then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_evaluated_string('')
          expect(b.value).to be_evaluated_string('123')
          expect(c.value).to be_evaluated_string('1, 2, 3')
          expect(d.value).to be_evaluated_string('PigeonBarn OwlParrot')
          expect(e.value).to be_evaluated_string('Pigeon---Barn Owl---Parrot')
          expect(f.value).to be_evaluated_string('PigeonBarn OwlParrotAlbatrossElf Owl')
          expect(g.value).to be_evaluated_string("Pigeon\nBarn Owl\nParrot\nAlbatross\nElf Owl")
        end
      end
    end
  end
end
