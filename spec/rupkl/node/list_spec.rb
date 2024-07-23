# frozen_string_literal: true

RSpec.describe RuPkl::Node::List do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  describe 'List method' do
    it 'should create a List object containing the given elements' do
      node = parse(<<~'PKL')
        a = List()
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list
      end

      node = parse(<<~'PKL')
        a = List(1, 2, 3)
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list(1, 2, 3)
      end

      node = parse(<<~'PKL')
        a = List(1, "x", List(1, 2, 3))
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_list(1, 'x', list(1, 2, 3))
      end
    end
  end
end
