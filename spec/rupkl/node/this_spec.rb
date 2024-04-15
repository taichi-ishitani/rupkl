# frozen_string_literal: true

RSpec.describe RuPkl::Node::This do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :expression)
    parser.parse(string.chomp, root: root)
  end

  describe '#evaluate' do
    it 'should return the current object' do
      node = parse(<<~'PKL')
        new Dynamic {
          foo = this.bar + 1
          bar = 3
        }
      PKL
      expect(node.evaluate(nil)).to (
        be_dynamic do |o|
          o.property :foo, 4
          o.property :bar, 3
        end
      )

      node = parse(<<~'PKL')
        new Mapping {
          ["one"] = 1
          ["two"] = this["one"] + 1
        }
      PKL
      expect(node.evaluate(nil)).to (
        be_mapping do |m|
          m['one'] = 1
          m['two'] = 2
        end
      )

      node = parse(<<~'PKL')
        new Listing {
          "one"
          this[0]
          "two"
          this[2]
          this[1] + this[3]
        }
      PKL
      expect(node.evaluate(nil)).to (
        be_listing do |l|
          l << 'one'
          l << 'one'
          l << 'two'
          l << 'two'
          l << 'onetwo'
        end
      )
    end
  end
end
