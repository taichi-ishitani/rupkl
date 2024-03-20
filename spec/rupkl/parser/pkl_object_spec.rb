# frozen_string_literal: true

RSpec.describe RuPkl::Parser::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'pkl object' do
    def parse(string)
      parse_string(string, :pkl_object)
    end

    it 'should be parsed by pkl object parser' do
      expect(parser).to parse('{}').as(pkl_object)

      expect(parser).to parse(<<~'PKL').as(pkl_object)
        {


        }
      PKL

      pkl = '{ 1 }'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.element 1
      end)

      pkl = '{ 1 2 3 }'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.element 1
        o.element 2
        o.element 3
      end)

      pkl = <<~'PKL'
        {
          1 ; 2
          3
        }
      PKL
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.element 1
        o.element 2
        o.element 3
      end)

      pkl = '{ foo = 1 }'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.property :foo, 1
      end)

      pkl = '{ foo = 1 bar = 2 }'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.property :foo, 1
        o.property :bar, 2
      end)

      pkl = '{["foo"] = 1 }'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.entry 'foo', 1
      end)

      pkl = '{["foo"] = 1 ["bar"] = 2}'
      expect(parser).to parse(pkl).as(pkl_object do |o|
        o.entry 'foo', 1
        o.entry 'bar', 2
      end)

      pkl = <<~'PKL'
        {
          name = "Common wood pigeon"
          diet = "Seeds"
          taxonomy {
            species = "Columba palumbus"
          }
        }
      PKL
      expect(parser).to parse(pkl).as(pkl_object do |o1|
        o1.property :name, 'Common wood pigeon'
        o1.property :diet, 'Seeds'
        o1.property :taxonomy, [
          pkl_object { |o2| o2.property :species, 'Columba palumbus' }
        ]
      end)

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
      expect(parser).to parse(pkl).as(pkl_object do |o1|
        o1.property :name, 'Pigeon'
        o1.property :lifespan, 8
        o1.element 'wing'
        o1.element 'claw'
        o1.entry 'wing', 'Not related to the _element_ "wing"'
        o1.element 42
        o1.property :extinct, false
        o1.entry false, [
          pkl_object { |o2| o2.property(:description, 'Construed object example') }
        ]
      end)

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
      expect(parser).to parse(pkl).as(pkl_object do |o1|
        o1.property :foo, [
          pkl_object do |o2|
            o2.property :bar, 0
            o2.element 1
            o2.entry 'baz', 2
          end,
          pkl_object do |o2|
            o2.property :bar, 3
            o2.element 4
            o2.entry 'baz', 5
          end
        ]
      end)
    end
  end
end
