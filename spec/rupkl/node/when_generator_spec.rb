# frozen_string_literal: true

RSpec.describe RuPkl::Node::WhenGenerator do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string, root: :pkl_module)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      parrot {
        lifespan = 20
        when (isSinger) {
          hobby = "singing"
          idol = "Frank Sinatra"
        }
      }
    PKL
    strings << <<~'PKL'
      abilities {
        "chirping"
        when (isSinger) {
          "singing"
        }
        "whistling"
      }
    PKL
    strings << <<~'PKL'
      abilitiesByBird {
        ["Barn owl"] = "hooing"
        when (isSinger) {
          ["Parrot"] = "singing"
        }
        ["Parrot"] = "whistling"
      }
    PKL
    strings << <<~'PKL'
      parrot {
        lifespan = 20
        when (isSinger) {
          hobby = "singing"
          idol = "Aretha Franklin"
        } else {
          hobby = "whistling"
          idol = "Wolfgang Amadeus Mozart"
        }
      }
    PKL
    strings << <<~'PKL'
      parrot {
        lifespan = 20
        when (isSinger) {
          hobby = "singing"
          idol = "Aretha Franklin"
        }
      }
      pigeon = (parrot) {
        when (!isSinger) {
          hobby = "whistling"
          idol = "Wolfgang Amadeus Mozart"
        }
      }
    PKL
  end

  context 'when the given condition is true'  do
    it 'should generate object members within the \'when\' body' do
      node = parse(<<~PKL)
        isSinger = true
        #{pkl_strings[0]}
      PKL
      node.evaluate(nil).properties[-1].then do |o|
        expect(o.value)
          .to (be_dynamic do |d|
            d.property :lifespan, 20
            d.property :hobby, 'singing'
            d.property :idol, 'Frank Sinatra'
          end)
      end

      node = parse(<<~PKL)
        isSinger = true
        #{pkl_strings[1]}
      PKL
      node.evaluate(nil).properties[-1].then do |o|
        expect(o.value)
          .to (be_dynamic { |d| d.element 'chirping'; d.element 'singing'; d.element 'whistling' })
      end

      node = parse(<<~PKL)
        isSinger = true
        #{pkl_strings[2]}
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'duplicate definition of member'

      node = parse(<<~PKL)
        isSinger = true
        #{pkl_strings[3]}
      PKL
      node.evaluate(nil).properties[-1].then do |o|
        expect(o.value)
          .to (be_dynamic do |d|
            d.property :lifespan, 20
            d.property :hobby, 'singing'
            d.property :idol, 'Aretha Franklin'
          end)
      end

      node = parse(<<~PKL)
        isSinger = true
        #{pkl_strings[4]}
      PKL
      node.evaluate(nil).properties[-1].then do |o|
        expect(o.value)
          .to (be_dynamic do |d|
            d.property :lifespan, 20
            d.property :hobby, 'singing'
            d.property :idol, 'Aretha Franklin'
          end)
      end
    end
  end

  context 'when the given condition is false'  do
    context 'and the \'else\' block is not given' do
      it 'should generate no object members' do
        node = parse(<<~PKL)
          isSinger = false
          #{pkl_strings[0]}
        PKL
        node.evaluate(nil).properties[-1].then do |o|
          expect(o.value)
            .to (be_dynamic do |d|
              d.property :lifespan, 20
            end)
        end

        node = parse(<<~PKL)
          isSinger = false
          #{pkl_strings[1]}
        PKL
        node.evaluate(nil).properties[-1].then do |o|
          expect(o.value)
            .to (be_dynamic { |d| d.element 'chirping'; d.element 'whistling' })
        end

        node = parse(<<~PKL)
          isSinger = false
          #{pkl_strings[2]}
        PKL
        node.evaluate(nil).properties[-1].then do |o|
          expect(o.value)
            .to (be_dynamic { |d| d.entry 'Barn owl', 'hooing'; d.entry 'Parrot', 'whistling' })
        end

        node = parse(<<~PKL)
          isSinger = false
          #{pkl_strings[4]}
        PKL
        node.evaluate(nil).properties[-1].then do |o|
          expect(o.value)
            .to (be_dynamic do |d|
              d.property :lifespan, 20
              d.property :hobby, 'whistling'
              d.property :idol, 'Wolfgang Amadeus Mozart'
            end)
        end
      end
    end

    context 'and the \'else\' block is given' do
      it 'should generate object members within the \'else\' block' do
        node = parse(<<~PKL)
          isSinger = false
          #{pkl_strings[3]}
        PKL
        node.evaluate(nil).properties[-1].then do |o|
          expect(o.value)
            .to (be_dynamic do |d|
              d.property :lifespan, 20
              d.property :hobby, 'whistling'
              d.property :idol, 'Wolfgang Amadeus Mozart'
            end)
        end
      end
    end
  end

  context 'when the given condition is not boolean' do
    it 'should raise EvaluationError' do
      node = parse(<<~'PKL')
        foo {
          when (1) {
            bar = 2
          }
        }
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'expected type \'Boolean\', but got type \'Int\''
    end
  end
end
