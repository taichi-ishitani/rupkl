# frozen_string_literal: true

RSpec.describe RuPkl do
  describe '.load' do
    let(:input) do
      <<~'PKL'
        name = "Pkl: Configure your Systems in New Ways"
        attendants = 100
        isInteractive = true
      PKL
    end

    it 'should load Pkl string' do
      expect(RuPkl.load(input)).to match_pkl_object(
        properties: {
          name: 'Pkl: Configure your Systems in New Ways',
          attendants: 100, isInteractive: true
        }
      )
    end

    it 'should load Pkl string from the given IO object' do
      io = StringIO.new(input)
      expect(RuPkl.load(io)).to match_pkl_object(
          properties: {
          name: 'Pkl: Configure your Systems in New Ways',
          attendants: 100, isInteractive: true
        }
      )
    end
  end

  describe '.load_file' do
    let(:input) do
      <<~'PKL'
        name = "Pkl: Configure your Systems in New Ways"
        attendants = 100
        isInteractive = true
      PKL
    end

    let(:input_file) do
      'test.pkl'
    end

    it 'should load Pkl string from the given file' do
      io = StringIO.new(input)
      allow(File).to receive(:open).with(input_file, 'r').and_yield(io)

      expect(RuPkl.load_file(input_file)).to match_pkl_object(
        properties: {
        name: 'Pkl: Configure your Systems in New Ways',
        attendants: 100, isInteractive: true
      }
    )
    end
  end
end
