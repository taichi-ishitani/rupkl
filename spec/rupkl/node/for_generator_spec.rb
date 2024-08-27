# frozen_string_literal: true

RSpec.describe RuPkl::Node::ForGenerator do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string, root: :pkl_module)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      b = new Mapping {
        for (v in a) {
          when (v.isOdd) {
            [v] = v
          }
        }
      }
      c = new Listing {
        for (v in a) {
          when (v.isOdd) {
            v
          }
        }
      }
    PKL
    strings << <<~'PKL'
      b = new Mapping {
        for (k, v in a) {
          when (v.isOdd) {
            [k] = v
          }
        }
      }
      c = new Listing {
        for (k, v in a) {
          when (v.isOdd) {
            k; v
          }
        }
      }
    PKL
  end

  it 'should generate object mebers in a loop' do
    node = parse(<<~PKL)
      a = IntSeq(1, 5)
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = IntSeq(1, 5)
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[0] = 1; m[2] = 3; m[4] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << 0; l << 1
        l << 2; l << 3
        l << 4; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = List(1, 2, 3, 4, 5)
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b,c )|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = List(1, 2, 3, 4, 5)
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[0] = 1; m[2] = 3; m[4] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << 0; l << 1
        l << 2; l << 3
        l << 4; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = Set(1, 2, 3, 4, 5)
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b,c )|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = Set(1, 2, 3, 4, 5)
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[0] = 1; m[2] = 3; m[4] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << 0; l << 1
        l << 2; l << 3
        l << 4; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = Map("1", 1, "2", 2, "3", 3, "4", 4, "5", 5)
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b,c )|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = Map("1", 1, "2", 2, "3", 3, "4", 4, "5", 5)
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m['1'] = 1; m['3'] = 3; m['5'] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << '1'; l << 1
        l << '3'; l << 3
        l << '5'; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = new Listing { 1; 2; 3; 4; 5 }
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b,c )|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = new Listing { 1; 2; 3; 4; 5 }
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[0] = 1; m[2] = 3; m[4] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << 0; l << 1
        l << 2; l << 3
        l << 4; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = new Mapping { ["1"] = 1; ["2"] = 2; ["3"] = 3; ["4"] = 4; ["5"] = 5 }
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b,c )|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = new Mapping{ ["1"] = 1; ["2"] = 2; ["3"] = 3; ["4"] = 4; ["5"] = 5 }
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m['1'] = 1; m['3'] = 3; m['5'] = 5;
      end)
      expect(c.value).to (be_listing do |l|
        l << '1'; l << 1
        l << '3'; l << 3
        l << '5'; l << 5
      end)
    end

    node = parse(<<~PKL)
      a = new Dynamic {
        a = 0; b = 1; c = 2;
        ["d"] = 3; ["e"] = 4; ["f"] = 5;
        6; 7; 8
      }
      #{pkl_strings[0]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m[1] = 1; m[3] = 3; m[5] = 5; m[7] = 7
      end)
      expect(c.value).to (be_listing do |l|
        l << 1; l << 3; l << 5; l << 7
      end)
    end

    node = parse(<<~PKL)
      a = new Dynamic {
        a = 0; b = 1; c = 2;
        ["d"] = 3; ["e"] = 4; ["f"] = 5;
        6; 7; 8
      }
      #{pkl_strings[1]}
    PKL
    node.evaluate(nil).properties[-2..].then do |(b, c)|
      expect(b.value).to (be_mapping do |m|
        m['b'] = 1; m['d'] = 3; m["f"] = 5; m[1] = 7
      end)
      expect(c.value).to (be_listing do |l|
        l << 'b'; l << 1
        l << 'd'; l << 3
        l << 'f'; l << 5
        l << 1  ; l << 7
      end)
    end

    node = parse(<<~'PKL')
      foo {
        for (i in IntSeq(0, 3)) { i }
      }
      bar = (foo) {
        for (i in IntSeq(4, 7)) { i }
      }
    PKL
    node.evaluate(nil).properties[-1].then do |bar|
      expect(bar.value).to (be_dynamic do |d|
        d << 0; d << 1; d << 2; d << 3
        d << 4; d << 5; d << 6; d << 7
      end)
    end
  end

  it 'cannot generate properties' do
    node = parse(<<~'PKL')
      foo {
        for (i in IntSeq(0, 1)) {
          bar = i
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'

    node = parse(<<~'PKL')
      foo {
        for (i in IntSeq(0, 1)) {
          local bar = i
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'

    node = parse(<<~'PKL')
      foo {
        for (i, j in IntSeq(0, 1)) {
          bar = i
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'

    node = parse(<<~'PKL')
      foo {
        for (i, j in IntSeq(0, 1)) {
          local bar = i
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'

    node = parse(<<~'PKL')
      foo {
        for (i in IntSeq(0, 1)) {
          when (true) {
            bar = i
          }
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'

    node = parse(<<~'PKL')
      foo {
        for (i, j in IntSeq(0, 1)) {
          when (true) {
            bar = i
          }
        }
      }
    PKL
    expect { node.evaluate(nil) }
      .to raise_evaluation_error 'cannot generate object properties'
  end

  context 'when the given iterable cannot be iterated' do
    it 'should raise EvaluationError' do
      node = parse(<<~'PKL')
        foo {
          for (i in 1) {
            ["bar"] = i
          }
        }
      PKL
      expect { node.evaluate(nil) }
        .to raise_evaluation_error 'cannot iterate over value of type \'Int\''
    end
  end
end
