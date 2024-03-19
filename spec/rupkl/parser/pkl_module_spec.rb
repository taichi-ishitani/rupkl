# frozen_string_literal: true

RSpec.describe RuPkl::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'pkl module' do
    def parse(string)
      parse_string(string, :pkl_module)
    end

    it 'should be parsed by module parser' do
      pkl = <<~'PKL'
      PKL
      expect(parser).to parse(pkl).as(pkl_module)

      pkl = <<~'PKL'



      PKL
      expect(parser).to parse(pkl).as(pkl_module)

      pkl = 'name="Pkl: Configure your Systems in New Ways"'
      expect(parser).to parse(pkl).as(pkl_module do |m|
        m.property :name, 'Pkl: Configure your Systems in New Ways'
      end)

      pkl = 'name="Pkl: Configure your Systems in New Ways";attendants=100'
      expect(parser).to parse(pkl).as(pkl_module do |m|
        m.property :name, 'Pkl: Configure your Systems in New Ways'
        m.property :attendants, 100
      end)

      pkl = 'name="Pkl: Configure your Systems in New Ways";attendants=100;isInteractive=true'
      expect(parser).to parse(pkl).as(pkl_module do |m|
        m.property :name, 'Pkl: Configure your Systems in New Ways'
        m.property :attendants, 100
        m.property :isInteractive, true
      end)

      pkl = <<~'PKL'

        name = "Pkl: Configure your Systems in New Ways"
        attendants = 100
        isInteractive = true

      PKL
      expect(parser).to parse(pkl).as(pkl_module do |m|
        m.property :name, 'Pkl: Configure your Systems in New Ways'
        m.property :attendants, 100
        m.property :isInteractive, true
      end)

      pkl = <<~'PKL'
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
      expect(parser).to parse(pkl).as(pkl_module do |m|
        m.property :mixedObject, [
          pkl_object do |o1|
            o1.property :name, 'Pigeon'
            o1.property :lifespan, 8
            o1.element 'wing'
            o1.element 'claw'
            o1.entry 'wing', 'Not related to the _element_ "wing"'
            o1.element 42
            o1.property :extinct, false
            o1.entry false, [
              pkl_object do |o2|
                o2.property :description, 'Construed object example'
              end
            ]
          end
        ]
      end)
    end
  end
end
