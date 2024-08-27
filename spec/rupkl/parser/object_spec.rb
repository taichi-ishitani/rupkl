# frozen_string_literal: true

RSpec.describe RuPkl::Parser::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'object' do
    def parse(string)
      parse_string(string, :object)
    end

    it 'should be parsed by object parser' do
      expect(parser).to parse('{}').as(
        unresolved_object { |o| o.body }
      )

      pkl = <<~'PKL'
        {


        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object { |o| o.body }
      )

      pkl = '{ 1 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.element 1 }
        end
      )

      pkl = '{ 1 2 3 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.element 1; b.element 2; b.element 3 }
        end
      )

      pkl = <<~'PKL'
        {
          1 ; 2
          3
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.element 1; b.element 2; b.element 3 }
        end
      )

      pkl = '{ foo = 1 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.property :foo, 1 }
        end
      )

      pkl = '{ foo = 1 bar = 2 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.property :foo, 1; b.property :bar, 2 }
        end
      )

      pkl = '{ local foo = 1 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.property :foo, 1, local: true }
        end
      )

      pkl = '{ local local foo = 1 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.property :foo, 1, local: true }
        end
      )

      pkl = '{["foo"] = 1 }'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.entry 'foo', 1 }
        end
      )

      pkl = '{["foo"] = 1 ["bar"] = 2}'
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body { |b| b.entry 'foo', 1; b.entry 'bar', 2 }
        end
      )

      pkl = <<~'PKL'
        {
          name = "Common wood pigeon"
          diet = "Seeds"
          taxonomy {
            species = "Columba palumbus"
          }
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o1|
          o1.body do |b1|
            b1.property :name, 'Common wood pigeon'
            b1.property :diet, 'Seeds'
            b1.property :taxonomy, (
              unresolved_object do |o2|
                o2.body { |b2| b2.property :species, 'Columba palumbus' }
              end
            )
          end
        end
      )

      pkl = <<~'PKL'
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
      expect(parser).to parse(pkl).as(
        unresolved_object do |o1|
          o1.body do |b1|
            b1.property :name, 'Pigeon'
            b1.property :lifespan, 8
            b1.element 'wing'
            b1.element 'claw'
            b1.entry 'wing', 'Not related to the _element_ "wing"'
            b1.element 42
            b1.property :extinct, false
            b1.entry false, (
              unresolved_object do |o2|
                o2.body { |b2| b2.property:description, 'Construed object example' }
              end
            )
          end
        end
      )

      pkl = <<~'PKL'
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
      expect(parser).to parse(pkl).as(
        unresolved_object do |o1|
          o1.body do |b1|
            b1.property :foo, (
              unresolved_object do |o2|
                o2.body { |b2| b2.property :bar, 0; b2.element 1; b2.entry 'baz', 2 }
                o2.body { |b2| b2.property :bar, 3; b2.element 4; b2.entry 'baz', 5 }
              end
            )
          end
        end
      )

      pkl = <<~'PKL'
        {
          function foo() = a * b * c
          function bar(a) = a * b * c
          function baz(a, b) = a * b * c
          function qux(a, b, c) = a * b * c
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body do |b|
            b.method(:foo, body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
            b.method(:bar, params: [param(:a)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
            b.method(:baz, params: [param(:a), param(:b)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
            b.method(:qux, params: [param(:a), param(:b), param(:c)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
          end
        end
      )

      pkl = <<~'PKL'
        {
          function sum1(a: Int, b: Int): Int = a + b
          function sum2(a: Number, b: Number): Number = a + b
          function sum3(a: Int, b: Int): Int = 1.1
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body do |b|
            b.method(
              :sum1, params: [param(:a, declared_type(:Int)), param(:b, declared_type(:Int))],
              type: declared_type(:Int), body: b_op(:+, member_ref(:a),  member_ref(:b))
            )
            b.method(
              :sum2, params: [param(:a, declared_type(:Number)), param(:b, declared_type(:Number))],
              type: declared_type(:Number), body: b_op(:+, member_ref(:a),  member_ref(:b))
            )
            b.method(
              :sum3, params: [param(:a, declared_type(:Int)), param(:b, declared_type(:Int))],
              type: declared_type(:Int), body: be_float(1.1)
            )
          end
        end
      )

      pkl = <<~'PKL'
        {
          when (isSinger) {
            hobby = "singing"
            idol = "Frank Sinatra"
          }
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body do |b0|
            b0.when_generator do |g|
              g.condition member_ref(:isSinger)
              g.when_body { |b1| b1.property :hobby, 'singing'; b1.property :idol, 'Frank Sinatra' }
            end
          end
        end
      )

      pkl = <<~'PKL'
        {
          "chirping"
          when (isSinger) {
            "singing"
          }
          "whistling"
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body do |b0|
            b0.element 'chirping'
            b0.when_generator do |g|
              g.condition member_ref(:isSinger)
              g.when_body { |b1| b1.element 'singing' }
            end
            b0.element 'whistling'
          end
        end
      )

      pkl = <<~'PKL'
        {
          when (isSinger) {
            hobby = "singing"
            idol = "Aretha Franklin"
          } else {
            hobby = "whistling"
            idol = "Wolfgang Amadeus Mozart"
          }
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o|
          o.body do |b0|
            b0.when_generator do |g|
              g.condition member_ref(:isSinger)
              g.when_body { |b1| b1.property :hobby, 'singing'; b1.property :idol, 'Aretha Franklin' }
              g.else_body { |b1| b1.property :hobby, 'whistling'; b1.property :idol, 'Wolfgang Amadeus Mozart' }
            end
          end
        end
      )

      pkl = <<~'PKL'
        {
          for (_name in names) {
            new {
              name = _name
              lifespan = 42
            }
          }
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o0|
          o0.body do |b0|
            b0.for_generator(:_name, member_ref(:names)) do |b1|
              b1.element(unresolved_object do |o1|
                o1.body { |b2| b2.property :name, member_ref(:_name); b2.property :lifespan, 42 }
              end)
            end
          end
        end
      )

      pkl = <<~'PKL'
        {
          for (_name, _lifespan in namesAndLifespans) {
            [_name] {
              name = _name
              lifespan = _lifespan
            }
          }
        }
      PKL
      expect(parser).to parse(pkl).as(
        unresolved_object do |o0|
          o0.body do |b0|
            b0.for_generator(:_name, :_lifespan, member_ref(:namesAndLifespans)) do |b1|
              b1.entry(member_ref(:_name), unresolved_object do |o1|
                o1.body { |b2| b2.property :name, member_ref(:_name); b2.property :lifespan, member_ref(:_lifespan) }
              end)
            end
          end
        end
      )
    end
  end
end
