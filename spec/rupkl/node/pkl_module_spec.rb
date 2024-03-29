# frozen_string_literal: true

RSpec.describe RuPkl::Node::PklModule do
  let(:parser) do
    RuPkl::Parser.new
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
    PKL
    strings << <<~'PKL'
      message = """
        Although the Dodo is extinct,
        the species will be remembered.
        """
      attendants = 100
      isInteractive = true
      amountLearned = 13.37
    PKL
    strings << <<~'PKL'
      exampleObjectWithJustIntElements {
        100
        42
      }

      exampleObjectWithMixedElements {
        "Bird Breeder Conference"
        (2000 + 23)
        exampleObjectWithJustIntElements
      }
    PKL
    strings << <<~'PKL'
      mixedObject {
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
      birds {
        "Pigeon"
        "Parrot"
        "Barn owl"
        "Falcon"
      }
      relatedToSnowOwl = birds[2]
    PKL
  end

  describe '#evaluate' do
    it 'should return a new pkl module having evaluated properties' do
      node = parser.parse(pkl_strings[0], root: :pkl_module)
      expect(node.evaluate(nil)).to be_pkl_module

      node = parser.parse(pkl_strings[1], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :message, "Although the Dodo is extinct,\nthe species will be remembered."
        m.property :attendants, 100
        m.property :isInteractive, true
        m.property :amountLearned, 13.37
      end)

      node = parser.parse(pkl_strings[2], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :exampleObjectWithJustIntElements, (
          dynamic do |o|
            o.element 100
            o.element 42
          end
        )
        m.property :exampleObjectWithMixedElements, (
          dynamic do |o1|
            o1.element 'Bird Breeder Conference'
            o1.element 2023
            o1.element (
              dynamic do |o2|
                o2.element 100
                o2.element 42
              end
            )
          end
        )
      end)

      node = parser.parse(pkl_strings[3], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :mixedObject, (
          dynamic do |o1|
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
      end)

      node = parser.parse(pkl_strings[4], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :birds, (
          dynamic do |o|
            o.element 'Pigeon'
            o.element 'Parrot'
            o.element 'Barn owl'
            o.element 'Falcon'
          end
        )
        m.property :relatedToSnowOwl, evaluated_string('Barn owl')
      end)
    end

    context 'when a property is being defined again' do
      it 'should raise EvaluationError' do
        node = parser.parse('foo = 1 foo = 2', root: :pkl_module)
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'duplicate definition of member'
      end
    end
  end

  describe '#to_ruby' do
    it 'should return a hash object contating evaluated properties' do
      node = parser.parse(pkl_strings[0], root: :pkl_module)
      expect(node.to_ruby(nil)).to be_empty

      node = parser.parse(pkl_strings[1], root: :pkl_module)
      expect(node.to_ruby(nil)).to match(
        message: "Although the Dodo is extinct,\nthe species will be remembered.",
        attendants: 100, isInteractive: true, amountLearned: 13.37
      )

      node = parser.parse(pkl_strings[2], root: :pkl_module)
      expect(node.to_ruby(nil))
        .to match(
          exampleObjectWithJustIntElements: match_dynamic(
            elements: [100, 42]
          ),
          exampleObjectWithMixedElements: match_dynamic(
            elements: [
              'Bird Breeder Conference',
              2023,
              match_dynamic(elements: [100, 42])
            ]
          )
        )

      node = parser.parse(pkl_strings[3], root: :pkl_module)
      expect(node.to_ruby(nil))
        .to match(
          mixedObject: match_dynamic(
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
        )

      node = parser.parse(pkl_strings[4], root: :pkl_module)
      expect(node.to_ruby(nil))
        .to match(
          birds: match_dynamic(
            elements: ['Pigeon', 'Parrot', 'Barn owl', 'Falcon']
          ),
          relatedToSnowOwl: 'Barn owl'
        )
    end
  end
end
