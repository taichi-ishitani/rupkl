# frozen_string_literal: true

RSpec.describe RuPkl::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'comment' do
    it 'should be ignored' do
      pkl = <<~'PKL'.chomp
        x = 10 // end-of-line comment

        y = 20 /*
        multi
        line
        /* nested */
        comment
        */ z = 30

        /// documentation comment
        a = 40

        b = 50 // single-line comment running until EOF rather than newline
      PKL

      expect(parser)
        .to parse_string(pkl, :pkl_module)
        .as(pkl_module(evaluated: false) do |m|
          m.property :x, 10
          m.property :y, 20
          m.property :z, 30
          m.property :a, 40
          m.property :b, 50
        end)
    end
  end
end
