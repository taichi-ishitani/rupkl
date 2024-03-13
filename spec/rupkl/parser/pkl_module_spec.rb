# frozen_string_literal: true

RSpec.describe RuPkl::Parser, :parser do
  let(:parser) do
    RuPkl::Parser.new(:pkl_module)
  end

  describe 'pkl module' do
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
    end
  end
end
