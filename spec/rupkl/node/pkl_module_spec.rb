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
  end

  describe '#evaluate' do
    it 'should return a new pkl module having evaluated properties' do
      node = parser.parse(pkl_strings[0], root: :pkl_module)
      expect(node.evaluate(nil)).to be_pkl_module

      node = parser.parse(pkl_strings[1], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :message, be_evaluated_string("Although the Dodo is extinct,\nthe species will be remembered.")
        m.property :attendants, 100
        m.property :isInteractive, true
      end)

      node = parser.parse(pkl_strings[2], root: :pkl_module)
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :mixedObject, (
          pkl_object do |o1|
            o1.property :name, evaluated_string('Pigeon')
            o1.property :lifespan, 8
            o1.element evaluated_string('wing')
            o1.element evaluated_string('claw')
            o1.entry evaluated_string('wing'), evaluated_string('Not related to the _element_ "wing"')
            o1.element 42
            o1.property :extinct, false
            o1.entry false, (
              pkl_object do |o2|
                o2.property :description, evaluated_string('Construed object example')
              end
            )
          end
        )
      end)
    end
  end

  describe '#to_ruby' do
    it 'should return a hash object contating evaluated properties' do
      node = parser.parse(pkl_strings[0], root: :pkl_module)
      expect(node.to_ruby(nil)).to be_empty

      node = parser.parse(pkl_strings[1], root: :pkl_module)
      expect(node.to_ruby(nil)).to match(
        message: "Although the Dodo is extinct,\nthe species will be remembered.",
        attendants: 100, isInteractive: true
      )

      node = parser.parse(pkl_strings[2], root: :pkl_module)
      expect(node.to_ruby(nil))
        .to match(
          mixedObject: match_pkl_object(
            properties: {
              name: 'Pigeon', lifespan: 8, extinct: false
            },
            elements: [
              'wing', 'claw', 42
            ],
            entries: {
              'wing' => 'Not related to the _element_ "wing"',
              false => match_pkl_object(
                properties: { description: 'Construed object example' }
              )
            }
          )
        )
    end
  end
end
