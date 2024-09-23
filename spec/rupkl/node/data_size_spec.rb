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

  describe 'unary operation' do
    context 'the given operation is defined' do
      it 'should execute the given operation' do
        node = parse(<<~'PKL')
          a = -4.mb
          b = -a
          c = --a
        PKL
        node.evaluate(nil).properties.then do |(a, b, c)|
          expect(a.value).to be_data_size(-4, unit: :mb)
          expect(b.value).to be_data_size(4, unit: :mb)
          expect(c.value).to be_data_size(-4, unit: :mb)
        end

        node = parse(<<~'PKL')
          a = -4.4.mb
          b = -a
          c = --a
        PKL
        node.evaluate(nil).properties.then do |(a, b, c)|
          expect(a.value).to be_data_size(-4.4, unit: :mb)
          expect(b.value).to be_data_size(4.4, unit: :mb)
          expect(c.value).to be_data_size(-4.4, unit: :mb)
        end
      end
    end

    context 'when the given operation is not defined' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          a = !(4.mb)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!@\' is not defined for DataSize type'

        node = parse(<<~'PKL')
          a = !(4.4.mb)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!@\' is not defined for DataSize type'
      end
    end
  end

  describe 'binary operation' do
    context 'when defined operation and valid operand are given' do
      it 'should execute the given operation' do
        # equality/inequality
        [
          ['2.kb', '2.kb'],
          ['2.0.kb', '2.kb'],
          ['2.kb', '2.0.kb'],
          ['2.kib', '2048.b'],
          ['2048.b', '2.kib'],
          ['2.048.kb', '2.kib'],
          ['2.kib', '2.048.kb']
        ].each do |(a, b)|
          node = parse(<<~PKL)
            a = #{a}
            b = #{b}
            c = a == b
            d = a != b
          PKL
          node.evaluate(nil).properties[-2..].then do |(c, d)|
            expect(c.value).to be_boolean(true)
            expect(d.value).to be_boolean(false)
          end
        end

        [
          ['2.kb', '3.kb'],
          ['2.2.kb', '3.3.kb'],
          ['2.kb', '3.3.kb'],
          ['2.2.kb', '3.kb'],
          ['2.kb', '2.kib'],
          ['2.kib', '2.kb'],
          ['2.kb', '2000'],
          ['2.kib', '2028'],
          ['2.kb', '"foo"'],
          ['2.kb', 'true'],
          ['2.kb', 'new Dynamic {}'],
          ['2.kb', 'new Listing {}'],
          ['2.kb', 'new Mapping {}']
        ].each do |(a, b)|
          node = parse(<<~PKL)
            a = #{a}
            b = #{b}
            c = a != b
            d = a == b
          PKL
          node.evaluate(nil).properties[-2..].then do |(c, d)|
            expect(c.value).to be_boolean(true)
            expect(d.value).to be_boolean(false)
          end
        end

        # greater than/less than
        [
          ['3.kb', '2.kb', [true, false, false, true]],
          ['3.0.kb', '2.0.kb', [true, false, false, true]],
          ['3.kb', '2.0.kb', [true, false, false, true]],
          ['3.0.kb', '2.kb', [true, false, false, true]],
          ['2.kib', '2.kb', [true, false, false, true]],
          ['2.kib', '2.047.kb', [true, false, false, true]],
          ['2.kb', '2.kb', [false, false, false, false]],
          ['2.kb', '2000.b', [false, false, false, false]]
        ].each do |(a, b, (exp_c, exp_d, exp_e, exp_f))|
          node = parse(<<~PKL)
            a = #{a}
            b = #{b}
            c = a > b
            d = b > a
            e = a < b
            f = b < a
          PKL
          node.evaluate(nil).properties[-4..].then do |(c, d, e, f)|
            expect(c.value).to be_boolean(exp_c)
            expect(d.value).to be_boolean(exp_d)
            expect(e.value).to be_boolean(exp_e)
            expect(f.value).to be_boolean(exp_f)
          end
        end

        # greater than or equal/less than or equal
        [
          ['3.kb', '2.kb', [true, false, false, true]],
          ['3.0.kb', '2.0.kb', [true, false, false, true]],
          ['3.kb', '2.0.kb', [true, false, false, true]],
          ['3.0.kb', '2.kb', [true, false, false, true]],
          ['2.kib', '2.kb', [true, false, false, true]],
          ['2.kib', '2.047.kb', [true, false, false, true]],
          ['2.kb', '2.kb', [true, true, true, true]],
          ['2.kb', '2000.b', [true, true, true, true]]
        ].each do |(a, b, (exp_c, exp_d, exp_e, exp_f))|
          node = parse(<<~PKL)
            a = #{a}
            b = #{b}
            c = a >= b
            d = b >= a
            e = a <= b
            f = b <= a
          PKL
          node.evaluate(nil).properties[-4..].then do |(c, d, e, f)|
            expect(c.value).to be_boolean(exp_c)
            expect(d.value).to be_boolean(exp_d)
            expect(e.value).to be_boolean(exp_e)
            expect(f.value).to be_boolean(exp_f)
          end
        end

        # addition
        node = parse(<<~'PKL')
          a = 2.kb + 4.kb
          b = 2.2.kb + 3.3.kb
          c = 2.kb + 3.kib
          d = 10.b + 11.pib
          e = 4.kb + 2.kb
          f = 3.3.kb + 2.2.kb
          g = 3.kib + 2.kb
          h = 11.pib + 10.b
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_data_size(6, unit: :kb)
          expect(b.value).to be_data_size(5.5, unit: :kb)
          expect(c.value).to be_data_size(4.953125, unit: :kib)
          expect(d.value).to be_data_size(11.000000000000009, unit: :pib)
          expect(e.value).to be_data_size(6, unit: :kb)
          expect(f.value).to be_data_size(5.5, unit: :kb)
          expect(g.value).to be_data_size(4.953125, unit: :kib)
          expect(h.value).to be_data_size(11.000000000000009, unit: :pib)
        end

        # subtraction
        node = parse(<<~'PKL')
          a = 2.kb - 4.kb
          b = 2.2.kb - 3.3.kb
          c = 2.kb - 3.kib
          d = 10.b - 11.pib
          e = 4.kb - 2.kb
          f = 3.3.kb - 2.2.kb
          g = 3.kib - 2.kb
          h = 11.pib - 10.b
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_data_size(-2, unit: :kb)
          expect(b.value).to be_data_size(-1.0999999999999996, unit: :kb)
          expect(c.value).to be_data_size(-1.046875, unit: :kib)
          expect(d.value).to be_data_size(-10.999999999999991, unit: :pib)
          expect(e.value).to be_data_size(2, unit: :kb)
          expect(f.value).to be_data_size(1.0999999999999996, unit: :kb)
          expect(g.value).to be_data_size(1.046875, unit: :kib)
          expect(h.value).to be_data_size(10.999999999999991, unit: :pib)
        end

        # multiplication
        node = parse(<<~'PKL')
          a = 2.kb * 3
          b = 2.kb * 3.3
          c = 2.2.kb * 3
          d = 2.2.kb * 3.3
          e = 3 * 2.kb
          f = 3.3 * 2.kb
          g = 3 * 2.2.kb
          h = 3.3 * 2.2.kb
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_data_size(6, unit: :kb)
          expect(b.value).to be_data_size(6.6, unit: :kb)
          expect(c.value).to be_data_size(6.6000000000000005, unit: :kb)
          expect(d.value).to be_data_size(7.26, unit: :kb)
          expect(e.value).to be_data_size(6, unit: :kb)
          expect(f.value).to be_data_size(6.6, unit: :kb)
          expect(g.value).to be_data_size(6.6000000000000005, unit: :kb)
          expect(h.value).to be_data_size(7.26, unit: :kb)
        end

        # division
        node = parse(<<~'PKL')
          a = 2.kb / 3
          b = 2.kb / 3.3
          c = 2.2.kb / 3
          d = 2.2.kb / 3.3
          e = 2.kb / 3.kb
          f = 2.kb / 3.3.kb
          g = 2.2.kb / 3.mb
          h = 2.2.mb / 3.3.b
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_data_size(0.6666666666666666, unit: :kb)
          expect(b.value).to be_data_size(0.6060606060606061, unit: :kb)
          expect(c.value).to be_data_size(0.7333333333333334, unit: :kb)
          expect(d.value).to be_data_size(0.6666666666666667, unit: :kb)
          expect(e.value).to be_float(0.6666666666666666)
          expect(f.value).to be_float(0.6060606060606061)
          expect(g.value).to be_float(7.333333333333333E-4)
          expect(h.value).to be_float(666666.6666666667)
        end

        # truncating division
        node = parse(<<~'PKL')
          a = 5.kb ~/ 3
          b = 7.kb ~/ 3.3
          c = 6.2.kb ~/ 3
          d = 6.2.kb ~/ 3.3
          e = 5.kb ~/ 3.kb
          f = 7.kb ~/ 3.3.kb
          g = 6.2.kb ~/ 3.mb
          h = 6.2.mb ~/ 3.3.b
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_data_size(1, unit: :kb)
          expect(b.value).to be_data_size(2, unit: :kb)
          expect(c.value).to be_data_size(2, unit: :kb)
          expect(d.value).to be_data_size(1, unit: :kb)
          expect(e.value).to be_int(1)
          expect(f.value).to be_int(2)
          expect(g.value).to be_int(0)
          expect(h.value).to be_int(1878787)
        end

        # remainder
        node = parse(<<~'PKL')
          a = 5.kb % 3
          b = 7.kb % 3.3
          c = 6.2.kb % 3
          d = 6.2.kb % 3.3
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_data_size(2, unit: :kb)
          expect(b.value).to be_data_size(0.40000000000000036, unit: :kb)
          expect(c.value).to be_data_size(0.20000000000000018, unit: :kb)
          expect(d.value).to be_data_size(2.9000000000000004, unit: :kb)
        end

        # power
        node = parse(<<~'PKL')
          a = 2.kb ** 3
          b = 2.kb ** 3.3
          c = 2.2.kb ** 3
          d = 2.2.kb ** 3.3
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_data_size(8, unit: :kb)
          expect(b.value).to be_data_size(9.849155306759329, unit: :kb)
          expect(c.value).to be_data_size(10.648000000000003, unit: :kb)
          expect(d.value).to be_data_size(13.489468760533386, unit: :kb)
        end
      end
    end

    context 'when the given operator is not defiend' do
      it 'should be raise EvaluationError' do
        node = parse(<<~'PKL')
          a = 1.kb || true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for DataSize type'

        node = parse(<<~'PKL')
          a = 1.1.kb || true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for DataSize type'

        node = parse(<<~'PKL')
          a = 1.kb && true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for DataSize type'

        node = parse(<<~'PKL')
          a = 1.1.kb && true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for DataSize type'
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-'
        ].each do |op|
        node = parse(<<~PKL)
          a = 1.kb #{op} 1
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} 1.0
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} 1
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} 1.0
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end

        ['*', '%', '**'].each do |op|
        node = parse(<<~PKL)
          a = 1.kb #{op} 2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} 2.2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} 2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} 2.2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end

        ['/', '~/'].each do |op|
        node = parse(<<~PKL)
          a = 1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.kb #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'value' do
      it 'should return the value of this data size' do
        node = parse(<<~'PKL')
          a = 1.b.value
          b = 2.2.kb.value
          c = 3.kib.value
          d = 4.4.mb.value
          e = 5.mib.value
          f = 6.6.gb.value
          g = 7.gib.value
          h = 8.8.tb.value
          i = 9.tib.value
          j = 10.1.pb.value
          k = 11.pib.value
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h, i, j, k)|
          expect(a.value).to be_int(1)
          expect(b.value).to be_float(2.2)
          expect(c.value).to be_int(3)
          expect(d.value).to be_float(4.4)
          expect(e.value).to be_int(5)
          expect(f.value).to be_float(6.6)
          expect(g.value).to be_int(7)
          expect(h.value).to be_float(8.8)
          expect(i.value).to be_int(9)
          expect(j.value).to be_float(10.1)
          expect(k.value).to be_int(11)
        end
      end
    end

    describe 'unit' do
      it 'should return the unit of this data size' do
        node = parse(<<~'PKL')
          a = 1.b.unit
          b = 2.2.kb.unit
          c = 3.kib.unit
          d = 4.4.mb.unit
          e = 5.mib.unit
          f = 6.6.gb.unit
          g = 7.gib.unit
          h = 8.8.tb.unit
          i = 9.tib.unit
          j = 10.1.pb.unit
          k = 11.pib.unit
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h, i, j, k)|
          expect(a.value).to be_evaluated_string('b')
          expect(b.value).to be_evaluated_string('kb')
          expect(c.value).to be_evaluated_string('kib')
          expect(d.value).to be_evaluated_string('mb')
          expect(e.value).to be_evaluated_string('mib')
          expect(f.value).to be_evaluated_string('gb')
          expect(g.value).to be_evaluated_string('gib')
          expect(h.value).to be_evaluated_string('tb')
          expect(i.value).to be_evaluated_string('tib')
          expect(j.value).to be_evaluated_string('pb')
          expect(k.value).to be_evaluated_string('pib')
        end
      end
    end

    describe 'isPositive' do
      it 'should tell if this data size has a value of zero or greater' do
        node = parse(<<~'PKL')
          a = 0.mb.isPositive
          b = 0.0.mb.isPositive
          c = 1.mb.isPositive
          d = 0.1.mb.isPositive
          e = (-0).mb.isPositive
          f = (-0.0).mb.isPositive
          g = (-1).mb.isPositive
          h = (-0.1).mb.isPositive
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(false)
          expect(h.value).to be_boolean(false)
        end
      end
    end

    describe 'isBinaryUnit' do
      it 'should tell if this data size has a binary unit' do
        node = parse(<<~'PKL')
          a = 1.pib.isBinaryUnit
          b = 2.tib.isBinaryUnit
          c = 3.gib.isBinaryUnit
          d = 4.mib.isBinaryUnit
          e = 5.kib.isBinaryUnit
          f = 6.b.isBinaryUnit
          g = 1.pb.isBinaryUnit
          h = 2.tb.isBinaryUnit
          i = 3.gb.isBinaryUnit
          j = 4.mb.isBinaryUnit
          k = 5.kb.isBinaryUnit
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h, i, j, k)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(false)
          expect(h.value).to be_boolean(false)
          expect(i.value).to be_boolean(false)
          expect(j.value).to be_boolean(false)
          expect(k.value).to be_boolean(false)
        end
      end
    end

    describe 'isDecimalUnit' do
      it 'should tells if this data size has a decimal unit' do
        node = parse(<<~'PKL')
          a = 1.pb.isDecimalUnit
          b = 2.tb.isDecimalUnit
          c = 3.gb.isDecimalUnit
          d = 4.mb.isDecimalUnit
          e = 5.kb.isDecimalUnit
          f = 6.b.isDecimalUnit
          g = 1.pib.isDecimalUnit
          h = 2.tib.isDecimalUnit
          i = 3.gib.isDecimalUnit
          j = 4.mib.isDecimalUnit
          k = 5.kib.isDecimalUnit
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h, i, j, k)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(true)
          expect(g.value).to be_boolean(false)
          expect(h.value).to be_boolean(false)
          expect(i.value).to be_boolean(false)
          expect(j.value).to be_boolean(false)
          expect(k.value).to be_boolean(false)
        end
      end
    end

    describe 'isBetween' do
      it 'should tell if this data size is greater than or equal to start and less than or equal to inclusiveEnd' do
        node = parse(<<~'PKL')
          a = 3.kb.isBetween(2.kb, 4.kb)
          b = 3.kb.isBetween(3.kb, 4.kb)
          c = 3.kb.isBetween(2.kb, 3.kb)
          d = 3.kb.isBetween(3.kb, 3.kb)
          e = 3.kb.isBetween(2000.b, 3000.b)
          f = 3.kb.isBetween(1.kb, 2.kb)
          g = 3.kb.isBetween(4.kb, 2.kb)
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(false)
          expect(g.value).to be_boolean(false)
        end

        node = parse(<<~'PKL')
          a = 3.3.kb.isBetween(2.2.kb, 4.4.kb)
          b = 3.3.kb.isBetween(3.3.kb, 4.4.kb)
          c = 3.3.kb.isBetween(2.2.kb, 3.3.kb)
          d = 3.3.kb.isBetween(3.3.kb, 3.3.kb)
          e = 3.3.kb.isBetween(2000.b, 3300.b)
          f = 3.3.kb.isBetween(1.1.kb, 2.2.kb)
          g = 3.3.kb.isBetween(4.4.kb, 2.2.kb)
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_boolean(true)
          expect(b.value).to be_boolean(true)
          expect(c.value).to be_boolean(true)
          expect(d.value).to be_boolean(true)
          expect(e.value).to be_boolean(true)
          expect(f.value).to be_boolean(false)
          expect(g.value).to be_boolean(false)
        end
      end
    end

    describe 'toUnit' do
      it 'should return the equivalent data size with the given unit' do
        node = parse(<<~'PKL')
          a = 1.pb.toUnit("pb")
          b = 1.pb.toUnit("tb")
          c = 1.pb.toUnit("gb")
          d = 1.pb.toUnit("mb")
          e = 1.pb.toUnit("kb")
          f = 1.pb.toUnit("b")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(1, unit: :pb)
          expect(b.value).to be_data_size(1000, unit: :tb)
          expect(c.value).to be_data_size(1000000, unit: :gb)
          expect(d.value).to be_data_size(1000000000, unit: :mb)
          expect(e.value).to be_data_size(1000000000000, unit: :kb)
          expect(f.value).to be_data_size(1000000000000000, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 1.pb.toUnit("b").toUnit("pb")
          b = 1.pb.toUnit("b").toUnit("tb")
          c = 1.pb.toUnit("b").toUnit("gb")
          d = 1.pb.toUnit("b").toUnit("mb")
          e = 1.pb.toUnit("b").toUnit("kb")
          f = 1.pb.toUnit("b").toUnit("b")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(1, unit: :pb)
          expect(b.value).to be_data_size(1000, unit: :tb)
          expect(c.value).to be_data_size(1000000, unit: :gb)
          expect(d.value).to be_data_size(1000000000, unit: :mb)
          expect(e.value).to be_data_size(1000000000000, unit: :kb)
          expect(f.value).to be_data_size(1000000000000000, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 1.pib.toUnit("pib")
          b = 1.pib.toUnit("tib")
          c = 1.pib.toUnit("gib")
          d = 1.pib.toUnit("mib")
          e = 1.pib.toUnit("kib")
          f = 1.pib.toUnit("b")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(1, unit: :pib)
          expect(b.value).to be_data_size(1024, unit: :tib)
          expect(c.value).to be_data_size(1048576, unit: :gib)
          expect(d.value).to be_data_size(1073741824, unit: :mib)
          expect(e.value).to be_data_size(1099511627776, unit: :kib)
          expect(f.value).to be_data_size(1125899906842624, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 1.pib.toUnit("b").toUnit("pib")
          b = 1.pib.toUnit("b").toUnit("tib")
          c = 1.pib.toUnit("b").toUnit("gib")
          e = 1.pib.toUnit("b").toUnit("mib")
          d = 1.pib.toUnit("b").toUnit("kib")
          f = 1.pib.toUnit("b").toUnit("b")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(1, unit: :pib)
          expect(b.value).to be_data_size(1024, unit: :tib)
          expect(c.value).to be_data_size(1048576, unit: :gib)
          expect(d.value).to be_data_size(1073741824, unit: :mib)
          expect(e.value).to be_data_size(1099511627776, unit: :kib)
          expect(f.value).to be_data_size(1125899906842624, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 0.5.gb.toUnit("kb")
          b = 0.5.gb.toUnit("gib")
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_data_size(500000, unit: :kb)
          expect(b.value).to be_data_size(0.46566128730773926, unit: :gib)
        end
      end

      context 'when non data unit string is given' do
        it 'should raise EvaluationError' do
          node = parse(<<~'PKL')
            a = 1.pb.toUnit("foo")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected value of type ' \
                                       '"b"|"kb"|"kib"|"mb"|"mib"|"gb"|"gib"|"tb"|"tib"|"pb"|"pib", ' \
                                       'but got "foo"'
        end
      end
    end

    describe 'toBinaryUnit' do
      it 'should returns the equivalent data size with a binary unit' do
        node = parse(<<~'PKL')
          a = 1.024.pb.toBinaryUnit()
          b = 1.024.tb.toBinaryUnit()
          c = 1.024.gb.toBinaryUnit()
          d = 1.024.mb.toBinaryUnit()
          e = 1.024.kb.toBinaryUnit()
          f = 1.024.b.toBinaryUnit()
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(0.9094947017729282, unit: :pib)
          expect(b.value).to be_data_size(0.9313225746154785, unit: :tib)
          expect(c.value).to be_data_size(0.95367431640625, unit: :gib)
          expect(d.value).to be_data_size(0.9765625, unit: :mib)
          expect(e.value).to be_data_size(1, unit: :kib)
          expect(f.value).to be_data_size(1.024, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 1.024.pib.toBinaryUnit()
          b = 1.024.tib.toBinaryUnit()
          c = 1.024.gib.toBinaryUnit()
          d = 1.024.mib.toBinaryUnit()
          e = 1.024.kib.toBinaryUnit()
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e)|
          expect(a.value).to be_data_size(1.024, unit: :pib)
          expect(b.value).to be_data_size(1.024, unit: :tib)
          expect(c.value).to be_data_size(1.024, unit: :gib)
          expect(d.value).to be_data_size(1.024, unit: :mib)
          expect(e.value).to be_data_size(1.024, unit: :kib)
        end
      end
    end

    describe 'toDecimalUnit' do
      it 'should returns the equivalent data size with a decimal unit' do
        node = parse(<<~'PKL')
          a = 1.pb.toDecimalUnit()
          b = 1.tb.toDecimalUnit()
          c = 1.gb.toDecimalUnit()
          d = 1.mb.toDecimalUnit()
          e = 1.kb.toDecimalUnit()
          f = 1.b.toDecimalUnit()
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f)|
          expect(a.value).to be_data_size(1, unit: :pb)
          expect(b.value).to be_data_size(1, unit: :tb)
          expect(c.value).to be_data_size(1, unit: :gb)
          expect(d.value).to be_data_size(1, unit: :mb)
          expect(e.value).to be_data_size(1, unit: :kb)
          expect(f.value).to be_data_size(1, unit: :b)
        end

        node = parse(<<~'PKL')
          a = 1.pib.toDecimalUnit()
          b = 1.tib.toDecimalUnit()
          c = 1.gib.toDecimalUnit()
          d = 1.mib.toDecimalUnit()
          e = 1.kib.toDecimalUnit()
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e)|
          expect(a.value).to be_data_size(1.125899906842624, unit: :pb)
          expect(b.value).to be_data_size(1.099511627776, unit: :tb)
          expect(c.value).to be_data_size(1.073741824, unit: :gb)
          expect(d.value).to be_data_size(1.048576, unit: :mb)
          expect(e.value).to be_data_size(1.024, unit: :kb)
        end
      end
    end
  end
end
