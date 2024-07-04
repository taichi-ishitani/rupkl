# frozen_string_literal: true

RSpec.describe RuPkl::Node::NullCoalescingOperation do
  let(:parser) do
    RuPkl::Parser.new
  end

  context 'when the left side operand is a non null value' do
    it 'should return the left side operand' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        a = 1 ?? null
        b = 2 ?? 3 ?? 4
        c = 5 ?? (null!!)
        d = "Pigeon" ?? "Parrot"
      PKL
      node.evaluate(nil).properties.then do |(a, b, c, d)|
        expect(a.value).to be_int(1)
        expect(b.value).to be_int(2)
        expect(c.value).to be_int(5)
        expect(d.value).to be_evaluated_string('Pigeon')
      end
    end
  end

  context 'when the left side operand is a null value' do
    it 'should return the right side operand' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        a = null ?? 1
        b = null ?? null ?? 2
        c = null ?? "Parrot"
      PKL
      node.evaluate(nil).properties.then do |(a, b, c)|
        expect(a.value).to be_int(1)
        expect(b.value).to be_int(2)
        expect(c.value).to be_evaluated_string('Parrot')
      end
    end
  end
end
