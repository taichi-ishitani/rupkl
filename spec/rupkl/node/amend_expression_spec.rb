# frozen_string_literal: true

RSpec.describe RuPkl::Node::AmendExpression do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string.chomp, root: :pkl_module).evaluate(nil)
  end

  describe '#evaluate' do
    it 'should a new object formed by amending the target object' do
      pkl = <<~'PKL'
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
      PKL
      parse(pkl).properties[-1].then do |n|
        expect(n.value).to (
          be_dynamic do |o1|
            o1.property :name, 'Parrot'
            o1.property :diet, 'Berries'
            o1.property :taxonomy, (
              dynamic do |o2|
                o2.property :kingdom, 'Animalia'
                o2.property :clade, 'Dinosauria'
                o2.property :order, 'Psittaciformes'
              end
            )
          end
        )
      end

      pkl = <<~'PKL'
        woodPigeon {
          name = "Common wood pigeon"
          diet = "Seeds"
          taxonomy {
            species = "Columba palumbus"
          }
        }

        stockPigeon = (woodPigeon) {
          name = "Stock pigeon"
          taxonomy {
            species = "Columba oenas"
          }
        }

        dodo = (stockPigeon) {
          name = "Dodo"
          extinct = true
          taxonomy {
            species = "Raphus cucullatus"
          }
        }
      PKL
      parse(pkl).properties[-2..-1].then do |(n1, n2)|
        expect(n1.value).to (
          be_dynamic do |o1|
            o1.property :name, 'Stock pigeon'
            o1.property :diet, 'Seeds'
            o1.property :taxonomy, (dynamic { |o2| o2.property :species, 'Columba oenas' })
          end
        )
        expect(n2.value).to (
          be_dynamic do |o1|
            o1.property :name, 'Dodo'
            o1.property :diet, 'Seeds'
            o1.property :taxonomy, (dynamic { |o2| o2.property :species, 'Raphus cucullatus' })
            o1.property :extinct, true
          end
        )
      end

      pkl = <<~'PKL'
        favoriteFoods {
          "red berries"
          "blue berries"
          ["Barn owl"] {
            "mice"
          }
        }

        adultBirdFoods = (favoriteFoods) {
          [1] = "pebbles"
          "worms"
          ["Falcon"] {
            "insects"
            "amphibians"
          }
          ["Barn owl"] {
            "fish"
          }
        }
      PKL
      parse(pkl).properties[-1].then do |n|
        expect(n.value).to (
          be_dynamic do |o1|
            o1.entry 'Barn owl', (
              dynamic { |o2| o2.element 'mice'; o2.element 'fish' }
            )
            o1.entry 'Falcon', (
              dynamic { |o2| o2.element 'insects'; o2.element 'amphibians' }
            )
            o1.element 'red berries'
            o1.element 'pebbles'
            o1.element 'worms'
          end
        )
      end

      pkl = <<~'PKL'
        pigeon {
          name = "Common wood pigeon"
        } {
          extinct = false
        }

        dodo = (pigeon) {
          name = "Dodo"
        } {
          extinct = true
        }
      PKL
      parse(pkl).properties[-1].then do |n|
        expect(n.value).to (
          be_dynamic do |o|
            o.property :name, 'Dodo'
            o.property :extinct, true
          end
        )
      end

      pkl = <<~'PKL'
        x {
          foo {
            bar {
              num1 = 1
              num2 = 2
            }
            baz {
              num3 = 3
            }
          }
        }

        y = (x) {
          foo {
            bar {
              num1 = 11
              str = "str"
            }
            baz2 {
              num4 = 4
            }
          }
        }
      PKL
      parse(pkl).properties[-1].then do |y|
        expect(y.value).to (
          be_dynamic do |o1|
            o1.property :foo, (
              dynamic do |o2|
                o2.property :bar, (dynamic { |o3| o3.property :num1, 11; o3.property :num2, 2; o3.property :str, 'str' })
                o2.property :baz, (dynamic { |o3| o3.property :num3, 3 })
                o2.property :baz2, (dynamic { |o3| o3.property :num4, 4 })
              end
            )
          end
        )
      end

      pkl = <<~'PKL'
        v1 {
          foo {
            x = y
            y = 3
          }
        }

        v2 = (v1) {
          foo {
            y = 4
          }
        }

        v3 = (v1) {
          y = 5
        }
      PKL
      parse(pkl).properties[-2..-1].then do |(v2, v3)|
        expect(v2.value).to (
          be_dynamic do |o1|
            o1.property :foo, (dynamic { |o2| o2.property :x, 4; o2.property :y, 4 })
          end
        )
        expect(v3.value).to (
          be_dynamic do |o1|
            o1.property :foo, (dynamic { |o2| o2.property :x, 3; o2.property :y, 3 })
            o1.property :y, 5
          end
        )
      end

      pkl = <<~'PKL'
        v1 {
          foo {
            x = y
          }
          y = 3
        }

        v2 = (v1) {
          y = 4
        }

        v3 = (v1) {
          foo {
            y = 5
          }
        }
      PKL
      parse(pkl).properties[-2..-1].then do |(v2, v3)|
        expect(v2.value).to (
          be_dynamic do |o1|
            o1.property :foo, (dynamic { |o2| o2.property :x, 4 })
            o1.property :y, 4
          end
        )
        expect(v3.value).to (
          be_dynamic do |o1|
            o1.property :foo, (dynamic { |o2| o2.property :x, 3; o2.property :y, 5 })
            o1.property :y, 3
          end
        )
      end

      pkl = <<~'PKL'
        foo {
          local l = "original"
          x = l
        }
        bar = (foo) {
          local l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (be_dynamic { |o| o.property :x, "original" })
      end

      pkl = <<~'PKL'
        foo {
          local l = "original"
          x = l
        }
        bar = (foo) {
          l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (be_dynamic { |o| o.property :x, 'original'; o.property :l, 'override' })
      end

      pkl = <<~'PKL'
        foo {
          l = "original"
          x = l
        }
        bar = (foo) {
          local l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (be_dynamic { |o| o.property :l, 'original'; o.property :x, 'original' })
      end

      pkl = <<~'PKL'
        foo {
          local l = "original"
          bar {
            x = l
          }
        }
        bar = (foo) {
          local l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (
          be_dynamic do |o1|
            o1.property :bar, (dynamic { |o2| o2.property :x, 'original' })
          end
        )
      end

      pkl = <<~'PKL'
        foo {
          local l = "original"
          bar {
            x = l
          }
        }
        bar = (foo) {
          l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (
          be_dynamic do |o1|
            o1.property :bar, (dynamic { |o2| o2.property :x, 'original' })
            o1.property :l, 'override'
          end
        )
      end

      pkl = <<~'PKL'
        foo {
          l = "original"
          bar {
            x = l
          }
        }
        bar = (foo) {
          local l = "override"
        }
      PKL
      parse(pkl).properties[-1].then do |bar|
        expect(bar.value).to (
          be_dynamic do |o1|
            o1.property :l, 'original'
            o1.property :bar, (dynamic { |o2| o2.property :x, 'original' })
          end
        )
      end
    end

    context 'when the targer is not an object' do
      it 'should raise EvaluationError' do
        pkl = <<~'PKL'
          foo = 0
          bar = (foo) {}
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot amend the target type Int'

        pkl = <<~'PKL'
          foo = 0.0
          bar = (foo) {}
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot amend the target type Float'

        pkl = <<~'PKL'
          foo = true
          bar = (foo) {}
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot amend the target type Boolean'

        pkl = <<~'PKL'
          foo = "foo"
          bar = (foo) {}
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot amend the target type String'
      end
    end
  end
end
