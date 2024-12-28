# frozen_string_literal: true

RSpec.describe RuPkl::PklObject do
  let(:objects) do
    o = []
    o << described_class.new { [nil, nil, nil] }
    o << described_class.new { [{ foo: 0, bar: 1 }]}
    o << described_class.new { [nil, { 'baz' => 2, 'qux' => 3 }] }
    o << described_class.new { [nil, nil, [4, 5]] }
    o << described_class.new { [{foo: 0, bar: 1 }, { 'baz' => 2, 'qux' => 3 }, [4, 5]] }
    o << RuPkl.load(<<~'PKL')
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
    o << RuPkl.load('foo { foo = 0; bar = 1; baz = this }')
    o << RuPkl.load('foo { ["foo"] = 0; ["bar"] = 1; ["baz"] = this }')
    o << RuPkl.load('foo { 0; 1; this }')
  end

  it 'should have accessor methods for each property' do
    expect(objects[0]).not_to respond_to(:foo, :bar)
    expect(objects[1].foo).to eq 0
    expect(objects[1].bar).to eq 1
    expect(objects[2]).not_to respond_to(:foo, :bar)
    expect(objects[3]).not_to respond_to(:foo, :bar)
    expect(objects[4].foo).to eq 0
    expect(objects[4].bar).to eq 1
  end

  describe '#[]' do
    it 'should return the specified member' do
      expect(objects[1][:foo]).to eq 0
      expect(objects[1][:bar]).to eq 1

      expect(objects[2]['baz']).to eq 2
      expect(objects[2]['qux']).to eq 3

      expect(objects[3][0]).to eq 4
      expect(objects[3][1]).to eq 5
      expect(objects[3][-2]).to eq 4
      expect(objects[3][-1]).to eq 5

      expect(objects[4][:foo]).to eq 0
      expect(objects[4][:bar]).to eq 1
      expect(objects[4]['baz']).to eq 2
      expect(objects[4]['qux']).to eq 3
      expect(objects[4][0]).to eq 4
      expect(objects[4][1]).to eq 5
      expect(objects[4][-2]).to eq 4
      expect(objects[4][-1]).to eq 5

    end

    context 'when the specified member does not exist' do
      it 'should return nil' do
        expect(objects[0][:foo]).to be_nil
        expect(objects[0][:bar]).to be_nil
        expect(objects[0]['baz']).to be_nil
        expect(objects[0]['qux']).to be_nil
        expect(objects[0][0]).to be_nil
        expect(objects[0][1]).to be_nil

        expect(objects[1][:baz]).to be_nil
        expect(objects[1][:qux]).to be_nil
        expect(objects[1]['baz']).to be_nil
        expect(objects[1]['qux']).to be_nil
        expect(objects[1][0]).to be_nil
        expect(objects[1][1]).to be_nil

        expect(objects[2][:foo]).to be_nil
        expect(objects[2][:bar]).to be_nil
        expect(objects[2]['foo']).to be_nil
        expect(objects[2]['bar']).to be_nil
        expect(objects[2][0]).to be_nil
        expect(objects[2][1]).to be_nil

        expect(objects[3][:foo]).to be_nil
        expect(objects[3][:bar]).to be_nil
        expect(objects[3]['foo']).to be_nil
        expect(objects[3]['bar']).to be_nil
        expect(objects[3][2]).to be_nil
        expect(objects[3][3]).to be_nil

        expect(objects[4][:baz]).to be_nil
        expect(objects[4][:qux]).to be_nil
        expect(objects[4]['foo']).to be_nil
        expect(objects[4]['bar']).to be_nil
        expect(objects[4][2]).to be_nil
        expect(objects[4][3]).to be_nil
      end
    end
  end

  describe '#members' do
    it 'should return its members' do
      expect(objects[0].members).to be_empty
      expect(objects[1].members).to eq [[:foo, 0], [:bar, 1]]
      expect(objects[2].members).to eq [['baz', 2], ['qux', 3]]
      expect(objects[3].members).to eq [4, 5]
      expect(objects[4].members).to eq [[:foo, 0], [:bar, 1], ['baz', 2], ['qux', 3], 4, 5]
    end
  end

  describe '#each' do
    context 'when a block is given' do
      it 'should call the given block one for each member' do
        expect { |b| objects[0].each(&b) }.not_to yield_control

        expect { |b| objects[1].each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])

        expect { |b| objects[2].each(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])

        expect { |b| objects[3].each(&b) }
          .to yield_successive_args(4, 5)

        expect { |b| objects[4].each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1], ['baz', 2], ['qux', 3], 4, 5)
      end

      it 'should return the iterated array' do
        expect(objects[0].each {}).to be_empty
        expect(objects[1].each {}).to eq objects[1].members
        expect(objects[2].each {}).to eq objects[2].members
        expect(objects[3].each {}).to eq objects[3].members
        expect(objects[4].each {}).to eq objects[4].members
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each.each(&b) }.not_to yield_control

        expect { |b| objects[1].each.each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])

        expect { |b| objects[2].each.each(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])

        expect { |b| objects[3].each.each(&b) }
          .to yield_successive_args(4, 5)

        expect { |b| objects[4].each.each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1], ['baz', 2], ['qux', 3], 4, 5)
      end
    end
  end

  describe '#properties' do
    it 'returns its properties' do
      expect(objects[0].properties).to be_empty
      expect(objects[1].properties).to eq({ foo: 0, bar: 1 })
      expect(objects[2].properties).to be_empty
      expect(objects[3].properties).to be_empty
      expect(objects[4].properties).to eq({ foo: 0, bar: 1 })
    end
  end

  describe '#each_property' do
    context 'when a block is given' do
      it 'should call the given block once for each property' do
        expect { |b| objects[0].each_property(&b) }.not_to yield_control

        expect { |b| objects[1].each_property(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])

        expect { |b| objects[2].each_property(&b) }.not_to yield_control

        expect { |b| objects[3].each_property(&b) }.not_to yield_control

        expect { |b| objects[4].each_property(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])
      end

      it 'should return the iterated properties' do
        expect(objects[0].each_property {}).to be_empty
        expect(objects[1].each_property {}).to eq objects[1].properties
        expect(objects[2].each_property {}).to be_empty
        expect(objects[3].each_property {}).to be_empty
        expect(objects[4].each_property {}).to eq objects[4].properties
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each_property.each(&b) }.not_to yield_control

        expect { |b| objects[1].each_property.each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])

        expect { |b| objects[2].each_property.each(&b) }.not_to yield_control

        expect { |b| objects[3].each_property.each(&b) }.not_to yield_control

        expect { |b| objects[4].each_property.each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])
      end
    end
  end

  describe 'entries' do
    it 'should return its entries' do
      expect(objects[0].entries).to be_empty
      expect(objects[1].entries).to be_empty
      expect(objects[2].entries).to eq({ 'baz' => 2, 'qux' => 3 })
      expect(objects[3].entries).to be_empty
      expect(objects[4].entries).to eq({ 'baz' => 2, 'qux' => 3 })
    end
  end

  describe '#each_entry' do
    context 'when a block is given' do
      it 'should call the given block one for each entry' do
        expect { |b| objects[0].each_entry(&b) }.not_to yield_control

        expect { |b| objects[1].each_entry(&b) }.not_to yield_control

        expect { |b| objects[2].each_entry(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])

        expect { |b| objects[3].each_entry(&b) }.not_to yield_control

        expect { |b| objects[4].each_entry(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])
      end

      it 'should return the iterated entries' do
        expect(objects[0].each_entry {}).to be_empty
        expect(objects[1].each_entry {}).to be_empty
        expect(objects[2].each_entry {}).to eq objects[2].entries
        expect(objects[3].each_entry {}).to be_empty
        expect(objects[4].each_entry {}).to eq objects[4].entries
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[1].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[2].each_entry.each(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])

        expect { |b| objects[3].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[4].each_entry.each(&b) }
          .to yield_successive_args(['baz', 2], ['qux', 3])
      end
    end
  end

  describe '#elements' do
    it 'should return its elements' do
      expect(objects[0].elements).to be_empty
      expect(objects[1].elements).to be_empty
      expect(objects[2].elements).to be_empty
      expect(objects[3].elements).to eq([4, 5])
      expect(objects[4].elements).to eq([4, 5])
    end
  end

  describe '#each_element' do
    context 'when a block is given' do
      it 'should call the given block one for each element' do
        expect { |b| objects[0].each_element(&b) }.not_to yield_control

        expect { |b| objects[1].each_element(&b) }.not_to yield_control

        expect { |b| objects[2].each_element(&b) }.not_to yield_control

        expect { |b| objects[3].each_element(&b) }
          .to yield_successive_args(4, 5)

        expect { |b| objects[4].each_element(&b) }
          .to yield_successive_args(4, 5)
      end

      it 'should return the iterated elements' do
        expect(objects[0].each_element {}).to be_empty
        expect(objects[1].each_element {}).to be_empty
        expect(objects[2].each_element {}).to be_empty
        expect(objects[3].each_element {}).to eq objects[3].elements
        expect(objects[4].each_element {}).to eq objects[4].elements
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each_element.each(&b) }.not_to yield_control

        expect { |b| objects[1].each_element.each(&b) }.not_to yield_control

        expect { |b| objects[2].each_element.each(&b) }

        expect { |b| objects[3].each_element.each(&b) }
          .to yield_successive_args(4, 5)

        expect { |b| objects[4].each_element.each(&b) }
          .to yield_successive_args(4, 5)
      end
    end
  end

  describe '#to_s' do
    def eq_string(string)
      expectation =
        if RUBY_VERSION >= Gem::Version.new('3.4.0')
          string
            .gsub(/:(\w+)=>/) { "#{$1}: "}
            .gsub(/=>/, ' => ')
        else
          string
        end
      eq(expectation)
    end

    it 'should return a string representing itself' do
      expect(objects[0].to_s).to eq_string '{}'
      expect(objects[1].to_s).to eq_string '{:foo=>0, :bar=>1}'
      expect(objects[2].to_s).to eq_string '{"baz"=>2, "qux"=>3}'
      expect(objects[3].to_s).to eq_string '[4, 5]'
      expect(objects[4].to_s).to eq_string '{:foo=>0, :bar=>1, "baz"=>2, "qux"=>3, 4, 5}'
      expect(objects[5].to_s).to eq_string <<~'S'.chomp.tr("\n", ' ')
        {:mixedObject=>{:name=>"Pigeon", :lifespan=>8, :extinct=>false,
        "wing"=>"Not related to the _element_ \"wing\"",
        false=>{:description=>"Construed object example"}, "wing", "claw", 42}}
      S
      expect(objects[6].to_s).to eq_string '{:foo=>{:foo=>0, :bar=>1, :baz=>{...}}}'
      expect(objects[7].to_s).to eq_string '{:foo=>{"foo"=>0, "bar"=>1, "baz"=>{...}}}'
      expect(objects[8].to_s).to eq_string '{:foo=>[0, 1, [...]]}'
    end
  end

  describe '#pretty_print' do
    it 'should return pretty printed output representing itself' do
      expect { pp objects[0] }.to output(<<~'OUT').to_stdout
        {}
      OUT
      expect { pp objects[1] }.to output(<<~'OUT').to_stdout
        {:foo=>0, :bar=>1}
      OUT
      expect { pp objects[2] }.to output(<<~'OUT').to_stdout
        {"baz"=>2, "qux"=>3}
      OUT
      expect { pp objects[3] }.to output(<<~'OUT').to_stdout
        [4, 5]
      OUT
      expect { pp objects[4] }.to output(<<~'OUT').to_stdout
        {:foo=>0, :bar=>1, "baz"=>2, "qux"=>3, 4, 5}
      OUT
      expect { pp objects[5] }.to output(<<~'OUT').to_stdout
        {:mixedObject=>
          {:name=>"Pigeon",
           :lifespan=>8,
           :extinct=>false,
           "wing"=>"Not related to the _element_ \"wing\"",
           false=>{:description=>"Construed object example"},
           "wing",
           "claw",
           42}}
      OUT
      expect { pp objects[6] }.to output(<<~'OUT').to_stdout
        {:foo=>{:foo=>0, :bar=>1, :baz=>{...}}}
      OUT
      expect { pp objects[7] }.to output(<<~'OUT').to_stdout
        {:foo=>{"foo"=>0, "bar"=>1, "baz"=>{...}}}
      OUT
      expect { pp objects[8] }.to output(<<~'OUT').to_stdout
        {:foo=>[0, 1, [...]]}
      OUT
    end
  end
end
