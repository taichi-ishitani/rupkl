# frozen_string_literal: true

RSpec.describe RuPkl::Node::PklModule do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should return a new pkl module having evaluated properties' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
      PKL
      expect(node.evaluate(nil)).to be_pkl_module

      node = parser.parse(<<~'PKL', root: :pkl_module)
        message = """
          Although the Dodo is extinct,
          the species will be remembered.
          """
        attendants = 100
        isInteractive = true
      PKL
      expect(node.evaluate(nil)).to (be_pkl_module do |m|
        m.property :message, be_evaluated_string("Although the Dodo is extinct,\nthe species will be remembered.")
        m.property :attendants, 100
        m.property :isInteractive, true
      end)
    end
  end

  describe '#to_ruby' do
    it 'should return a hash object contating evaluated properties' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
      PKL
      expect(node.to_ruby(nil)).to be_empty

      node = parser.parse(<<~'PKL', root: :pkl_module)
        message = """
          Although the Dodo is extinct,
          the species will be remembered.
          """
        attendants = 100
        isInteractive = true
      PKL
      expect(node.to_ruby(nil)).to match(
        message: "Although the Dodo is extinct,\nthe species will be remembered.",
        attendants: 100, isInteractive: true
      )
    end
  end
end
