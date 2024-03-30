# frozen_string_literal: true

RSpec.describe RuPkl::PklObject do
  let(:objects) do
    o = []
    o << described_class.new(nil, nil, nil)
    o << described_class.new({ foo: 0, bar: 1 }, nil, nil)
    o << described_class.new(nil, [2, 3], nil)
    o << described_class.new(nil, nil, { 'baz' => 4, 'qux' => 5 })
    o << described_class.new({ foo: 0, bar: 1 }, [2, 3], { 'baz' => 4, 'qux' => 5 })
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

  describe '#members' do
    it 'should return its members' do
      expect(objects[0].members).to be_empty
      expect(objects[1].members).to eq [[:foo, 0], [:bar, 1]]
      expect(objects[2].members).to eq [[0, 2], [1, 3]]
      expect(objects[3].members).to eq [['baz', 4], ['qux', 5]]
      expect(objects[4].members).to eq [[:foo, 0], [:bar, 1], [0, 2], [1, 3], ['baz', 4], ['qux', 5]]
    end
  end

  describe '#each' do
    context 'when a block is given' do
      it 'should call the given block one for each member' do
        expect { |b| objects[0].each(&b) }.not_to yield_control

        expect { |b| objects[1].each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1])

        expect { |b| objects[2].each(&b) }
          .to yield_successive_args([0, 2], [1, 3])

        expect { |b| objects[3].each(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])

        expect { |b| objects[4].each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1], [0, 2], [1, 3], ['baz', 4], ['qux', 5])
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
          .to yield_successive_args([0, 2], [1, 3])

        expect { |b| objects[3].each.each(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])

        expect { |b| objects[4].each.each(&b) }
          .to yield_successive_args([:foo, 0], [:bar, 1], [0, 2], [1, 3], ['baz', 4], ['qux', 5])
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

  describe '#elements' do
    it 'should return its elements' do
      expect(objects[0].elements).to be_empty
      expect(objects[1].elements).to be_empty
      expect(objects[2].elements).to eq([2, 3])
      expect(objects[3].elements).to be_empty
      expect(objects[4].elements).to eq([2, 3])
    end
  end

  describe '#each_element' do
    context 'when a block is given' do
      it 'should call the given block one for each element' do
        expect { |b| objects[0].each_element(&b) }.not_to yield_control

        expect { |b| objects[1].each_element(&b) }.not_to yield_control

        expect { |b| objects[2].each_element(&b) }
          .to yield_successive_args(2, 3)

        expect { |b| objects[3].each_element(&b) }.not_to yield_control

        expect { |b| objects[4].each_element(&b) }
          .to yield_successive_args(2, 3)
      end

      it 'should return the iterated elements' do
        expect(objects[0].each_element {}).to be_empty
        expect(objects[1].each_element {}).to be_empty
        expect(objects[2].each_element {}).to eq objects[2].elements
        expect(objects[3].each_element {}).to be_empty
        expect(objects[4].each_element {}).to eq objects[4].elements
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each_element.each(&b) }.not_to yield_control

        expect { |b| objects[1].each_element.each(&b) }.not_to yield_control

        expect { |b| objects[2].each_element.each(&b) }
          .to yield_successive_args(2, 3)

        expect { |b| objects[3].each_element.each(&b) }

        expect { |b| objects[4].each_element.each(&b) }
          .to yield_successive_args(2, 3)
      end
    end
  end

  describe 'entries' do
    it 'should return its entries' do
      expect(objects[0].entries).to be_empty
      expect(objects[1].entries).to be_empty
      expect(objects[2].entries).to be_empty
      expect(objects[3].entries).to eq({ 'baz' => 4, 'qux' => 5 })
      expect(objects[4].entries).to eq({ 'baz' => 4, 'qux' => 5 })
    end
  end

  describe '#each_entry' do
    context 'when a block is given' do
      it 'should call the given block one for each entry' do
        expect { |b| objects[0].each_entry(&b) }.not_to yield_control

        expect { |b| objects[1].each_entry(&b) }.not_to yield_control

        expect { |b| objects[2].each_entry(&b) }.not_to yield_control

        expect { |b| objects[3].each_entry(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])

        expect { |b| objects[4].each_entry(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])
      end

      it 'should return the iterated entries' do
        expect(objects[0].each_entry {}).to be_empty
        expect(objects[1].each_entry {}).to be_empty
        expect(objects[2].each_entry {}).to be_empty
        expect(objects[3].each_entry {}).to eq objects[3].entries
        expect(objects[4].each_entry {}).to eq objects[4].entries
      end
    end

    context 'when no block is given' do
      it 'should return an Enumerator object' do
        expect { |b| objects[0].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[1].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[2].each_entry.each(&b) }.not_to yield_control

        expect { |b| objects[3].each_entry.each(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])

        expect { |b| objects[4].each_entry.each(&b) }
          .to yield_successive_args(['baz', 4], ['qux', 5])
      end
    end
  end
end
