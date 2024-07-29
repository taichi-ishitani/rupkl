# frozen_string_literal: true

RSpec.describe RuPkl::Node::Map do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = Map()
    PKL
    strings << <<~'PKL'
      a = Map(1, "one", 2, "two", 3, "three")
    PKL
    strings << <<~'PKL'
      a = Map(1, "x", 2, Map(3, 4))
    PKL
  end

  describe 'Map method' do
    it 'should create Map object containing the given entries' do
      node = parse(pkl_strings[0])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map
      end

      node = parse(pkl_strings[1])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'one', 2 => 'two', 3 => 'three' })
      end

      node = parse(pkl_strings[2])
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'x', 2 => map({ 3 => 4 }) })
      end

      node = parse(<<~'PKL')
        a = Map(1, 1, 2, 2, 1, 3, 2, 4)
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 3, 2 => 4 })
      end

      node = parse(<<~'PKL')
        a = Map(1, 1, 2, 2, 1, "three", 2, "four")
      PKL
      node.evaluate(nil).properties[-1].then do |a|
        expect(a.value).to be_map({ 1 => 'three', 2 => 'four' })
      end
    end

    context 'when the number of the given arguments is not a multiple of 2' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          a = Map(1)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'number of arguments must be a multiple of two'

        node = parse(<<~'PKL')
          a = Map(1, 2, 3)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'number of arguments must be a multiple of two'
      end
    end
  end
end
