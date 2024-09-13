# frozen_string_literal: true

RSpec.describe RuPkl::Node::DataSize do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = 1.b
    PKL
    strings << <<~'PKL'
      a = 2.kb
    PKL
    strings << <<~'PKL'
      a = 3.kib
    PKL
    strings << <<~'PKL'
      a = 4.mb
    PKL
    strings << <<~'PKL'
      a = 5.mib
    PKL
    strings << <<~'PKL'
      a = 6.gb
    PKL
    strings << <<~'PKL'
      a = 7.gib
    PKL
    strings << <<~'PKL'
      a = 8.tb
    PKL
    strings << <<~'PKL'
      a = 9.tib
    PKL
    strings << <<~'PKL'
      a = 10.pb
    PKL
    strings << <<~'PKL'
      a = 11.pib
    PKL
    strings << <<~'PKL'
      a = 1.1.b
    PKL
    strings << <<~'PKL'
      a = 2.2.kb
    PKL
    strings << <<~'PKL'
      a = 3.3.kib
    PKL
    strings << <<~'PKL'
      a = 4.4.mb
    PKL
    strings << <<~'PKL'
      a = 5.5.mib
    PKL
    strings << <<~'PKL'
      a = 6.6.gb
    PKL
    strings << <<~'PKL'
      a = 7.7.gib
    PKL
    strings << <<~'PKL'
      a = 8.8.tb
    PKL
    strings << <<~'PKL'
      a = 9.9.tib
    PKL
    strings << <<~'PKL'
      a = 10.10.pb
    PKL
    strings << <<~'PKL'
      a = 11.11.pib
    PKL
  end

  describe 'b/kb/kib/mb/mib/gb/gib/tb/tib/pb/pib properties' do
    it 'should create a DataSize object with this value and unit' do
      [
        [1, :b], [2, :kb], [3, :kib], [4, :mb], [5, :mib],
        [6, :gb], [7, :gib], [8, :tb], [9, :tib], [10, :pb], [11, :pib],
        [1.1, :b], [2.2, :kb], [3.3, :kib], [4.4, :mb], [5.5, :mib],
        [6.6, :gb], [7.7, :gib], [8.8, :tb], [9.9, :tib], [10.10, :pb], [11.11, :pib]
      ].each_with_index do |(value, unit), i|
        node = parse(pkl_strings[i])
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value).to be_data_size(value, unit: unit)
        end
      end
    end
  end

  describe '#evaluate' do
    it 'should return itself' do
      pkl_strings.each do |pkl|
        node = parse(pkl)
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value.evaluate(nil)).to equal(a.value)
        end
      end
    end
  end

  describe '#to_ruby' do
    it 'should return its value' do
      [
        [1, 1000**0], [2, 1000**1], [3, 1024**1], [4, 1000**2], [5, 1024**2],
        [6, 1000**3], [7, 1024**3], [8, 1000**4], [9, 1024**4], [10, 1000**5], [11, 1024**5],
        [1.1, 1000**0], [2.2, 1000**1], [3.3, 1024**1], [4.4, 1000**2], [5.5, 1024**2],
        [6.6, 1000**3], [7.7, 1024**3], [8.8, 1000**4], [9.9, 1024**4], [10.10, 1000**5], [11.11, 1024**5],
      ].each_with_index do |(value, unit), i|
        node = parse(pkl_strings[i])
        expect(node.to_ruby(nil)).to match_pkl_object(
          properties: { a: eq(value * unit) }
        )
      end
    end
  end

  describe '#to_string/#to_pkl_string' do
    it 'should return a string representing itself' do
      [
        [1, :b], [2, :kb], [3, :kib], [4, :mb], [5, :mib],
        [6, :gb], [7, :gib], [8, :tb], [9, :tib], [10, :pb], [11, :pib],
        [1.1, :b], [2.2, :kb], [3.3, :kib], [4.4, :mb], [5.5, :mib],
        [6.6, :gb], [7.7, :gib], [8.8, :tb], [9.9, :tib], [10.10, :pb], [11.11, :pib]
      ].each_with_index do |(value, unit), i|
        node = parse(pkl_strings[i])
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value.to_string(nil)).to eq "#{value}.#{unit}"
          expect(a.value.to_pkl_string(nil)).to eq "#{value}.#{unit}"
        end
      end
    end
  end
end
