# frozen_string_literal: true

RSpec.describe RuPkl::Node::Duration do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string, root: :pkl_module)
    parser.parse(string, root: root)
  end

  let(:pkl_strings) do
    strings = []
    strings << <<~'PKL'
      a = 1.ns
    PKL
    strings << <<~'PKL'
      a = 2.us
    PKL
    strings << <<~'PKL'
      a = 3.ms
    PKL
    strings << <<~'PKL'
      a = 4.s
    PKL
    strings << <<~'PKL'
      a = 5.min
    PKL
    strings << <<~'PKL'
      a = 6.h
    PKL
    strings << <<~'PKL'
      a = 7.d
    PKL
    strings << <<~'PKL'
      a = 1.1.ns
    PKL
    strings << <<~'PKL'
      a = 2.2.us
    PKL
    strings << <<~'PKL'
      a = 3.3.ms
    PKL
    strings << <<~'PKL'
      a = 4.4.s
    PKL
    strings << <<~'PKL'
      a = 5.5.min
    PKL
    strings << <<~'PKL'
      a = 6.6.h
    PKL
    strings << <<~'PKL'
      a = 7.7.d
    PKL
  end

  describe 'ns/us/ms/s/min/h/d properties' do
    it 'should create a Duration object with this value and unit' do
      [
        [1, :ns], [2, :us], [3, :ms], [4, :s], [5, :min], [6, :h], [7, :d],
        [1.1, :ns], [2.2, :us], [3.3, :ms], [4.4, :s], [5.5, :min], [6.6, :h], [7.7, :d]
      ].each_with_index do |(value, unit), i|
        node = parse(pkl_strings[i])
        node.evaluate(nil).properties[-1].then do |a|
          expect(a.value).to be_duration(value, unit: unit)
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
        [1, 10.0**-9], [2, 10.0**-6], [3, 10.0**-3], [4, 1], [5, 60], [6, 60*60], [7, 24*60*60],
        [1.1, 10.0**-9], [2.2, 10.0**-6], [3.3, 10.0**-3], [4.4, 1], [5.5, 60], [6.6, 60*60], [7.7, 24*60*60]
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
        [1, :ns], [2, :us], [3, :ms], [4, :s], [5, :min], [6, :h], [7, :d],
        [1.1, :ns], [2.2, :us], [3.3, :ms], [4.4, :s], [5.5, :min], [6.6, :h], [7.7, :d]
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
          a = -4.s
          b = -a
          c = --a
        PKL
        node.evaluate(nil).properties.then do |(a, b, c)|
          expect(a.value).to be_duration(-4, unit: :s)
          expect(b.value).to be_duration(4, unit: :s)
          expect(c.value).to be_duration(-4, unit: :s)
        end

        node = parse(<<~'PKL')
          a = -4.4.s
          b = -a
          c = --a
        PKL
        node.evaluate(nil).properties.then do |(a, b, c)|
          expect(a.value).to be_duration(-4.4, unit: :s)
          expect(b.value).to be_duration(4.4, unit: :s)
          expect(c.value).to be_duration(-4.4, unit: :s)
        end
      end
    end

    context 'when the given operation is not defined' do
      it 'should raise EvaluationError' do
        node = parse(<<~'PKL')
          a = !(4.s)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!@\' is not defined for Duration type'

        node = parse(<<~'PKL')
          a = !(4.4.s)
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'!@\' is not defined for Duration type'
      end
    end
  end

  describe 'binary operation' do
    context 'when defined operation and valid operand are given' do
      it 'should execute the given operation' do
        # equality/inequality
        [
          ['2.s', '2.s'],
          ['2.0.s', '2.s'],
          ['2.s', '2.0.s'],
          ['2.s', '2000.ms'],
          ['2000.ms', '2.s'],
          ['60.s', '1.min'],
          ['1.min', '60.s'],
          ['0.002.s', '2.ms'],
          ['2.ms', '0.002.s']
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
          ['2.s', '3.s'],
          ['2.2.s', '3.3.s'],
          ['2.s', '3.3.s'],
          ['2.2.s', '3.s'],
          ['2.s', '2'],
          ['2.s', '"foo"'],
          ['2.s', 'true'],
          ['2.s', 'new Dynamic {}'],
          ['2.s', 'new Listing {}'],
          ['2.s', 'new Mapping {}']
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
          ['3.s', '2.s', [true, false, false, true]],
          ['3.0.s', '2.0.s', [true, false, false, true]],
          ['3.s', '2.0.s', [true, false, false, true]],
          ['3.0.s', '2.s', [true, false, false, true]],
          ['1.min', '59.s', [true, false, false, true]],
          ['1.s', '999.ms', [true, false, false, true]],
          ['2.s', '2.s', [false, false, false, false]],
          ['2.min', '120.s', [false, false, false, false]]
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
          ['3.s', '2.s', [true, false, false, true]],
          ['3.0.s', '2.0.s', [true, false, false, true]],
          ['3.s', '2.0.s', [true, false, false, true]],
          ['3.0.s', '2.s', [true, false, false, true]],
          ['1.min', '59.s', [true, false, false, true]],
          ['1.s', '999.ms', [true, false, false, true]],
          ['2.s', '2.s', [true, true, true, true]],
          ['2.min', '120.s', [true, true, true, true]]
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
          a = 2.s + 4.s
          b = 2.2.s + 3.3.s
          c = 2.s + 3.min
          d = 10.ns + 7.d
          e = 4.s + 2.s
          f = 3.3.s + 2.2.s
          g = 3.min + 2.s
          h = 7.d + 10.ns
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_duration(6, unit: :s)
          expect(b.value).to be_duration(5.5, unit: :s)
          expect(c.value).to be_duration(3.033333333333333, unit: :min)
          expect(d.value).to be_duration(7.0000000000001155, unit: :d)
          expect(e.value).to be_duration(6, unit: :s)
          expect(f.value).to be_duration(5.5, unit: :s)
          expect(g.value).to be_duration(3.033333333333333, unit: :min)
          expect(h.value).to be_duration(7.0000000000001155, unit: :d)
        end

        # subtraction
        node = parse(<<~'PKL')
          a = 2.s - 4.s
          b = 2.2.s - 3.3.s
          c = 2.s - 3.min
          d = 10.ns - 7.d
          e = 4.s - 2.s
          f = 3.3.s - 2.2.s
          g = 3.min - 2.s
          h = 7.d - 10.ns
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_duration(-2, unit: :s)
          expect(b.value).to be_duration(-1.0999999999999996, unit: :s)
          expect(c.value).to be_duration(-2.966666666666667, unit: :min)
          expect(d.value).to be_duration(-6.9999999999998845, unit: :d)
          expect(e.value).to be_duration(2, unit: :s)
          expect(f.value).to be_duration(1.0999999999999996, unit: :s)
          expect(g.value).to be_duration(2.966666666666667, unit: :min)
          expect(h.value).to be_duration(6.9999999999998845, unit: :d)
        end

        # multiplication
        node = parse(<<~'PKL')
          a = 2.s * 3
          b = 2.s * 3.3
          c = 2.2.s * 3
          d = 2.2.s * 3.3
          e = 3 * 2.s
          f = 3.3 * 2.s
          g = 3 * 2.2.s
          h = 3.3 * 2.2.s
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_duration(6, unit: :s)
          expect(b.value).to be_duration(6.6, unit: :s)
          expect(c.value).to be_duration(6.6000000000000005, unit: :s)
          expect(d.value).to be_duration(7.26, unit: :s)
          expect(e.value).to be_duration(6, unit: :s)
          expect(f.value).to be_duration(6.6, unit: :s)
          expect(g.value).to be_duration(6.6000000000000005, unit: :s)
          expect(h.value).to be_duration(7.26, unit: :s)
        end

        # division
        node = parse(<<~'PKL')
          a = 2.s / 3
          b = 2.s / 3.3
          c = 2.2.s / 3
          d = 2.2.s / 3.3
          e = 2.s / 3.s
          f = 2.s / 3.3.s
          g = 2.2.s / 3.min
          h = 2.2.h / 3.3.s
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_duration(0.6666666666666666, unit: :s)
          expect(b.value).to be_duration(0.6060606060606061, unit: :s)
          expect(c.value).to be_duration(0.7333333333333334, unit: :s)
          expect(d.value).to be_duration(0.6666666666666667, unit: :s)
          expect(e.value).to be_float(0.6666666666666666)
          expect(f.value).to be_float(0.6060606060606061)
          expect(g.value).to be_float(0.012222222222222223)
          expect(h.value).to be_float(2400.0000000000005)
        end

        # truncating division
        node = parse(<<~'PKL')
          a = 5.s ~/ 3
          b = 7.s ~/ 3.3
          c = 6.2.s ~/ 3
          d = 6.2.s ~/ 3.3
          e = 5.s ~/ 3.s
          f = 7.s ~/ 3.3.s
          g = 6.2.s ~/ 3.min
          h = 6.2.h ~/ 3.3.s
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h)|
          expect(a.value).to be_duration(1, unit: :s)
          expect(b.value).to be_duration(2, unit: :s)
          expect(c.value).to be_duration(2, unit: :s)
          expect(d.value).to be_duration(1, unit: :s)
          expect(e.value).to be_int(1)
          expect(f.value).to be_int(2)
          expect(g.value).to be_int(0)
          expect(h.value).to be_int(6763)
        end

        # remainder
        node = parse(<<~'PKL')
          a = 5.s % 3
          b = 7.s % 3.3
          c = 6.2.s % 3
          d = 6.2.s % 3.3
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_duration(2, unit: :s)
          expect(b.value).to be_duration(0.40000000000000036, unit: :s)
          expect(c.value).to be_duration(0.20000000000000018, unit: :s)
          expect(d.value).to be_duration(2.9000000000000004, unit: :s)
        end

        # power
        node = parse(<<~'PKL')
          a = 2.s ** 3
          b = 2.s ** 3.3
          c = 2.2.s ** 3
          d = 2.2.s ** 3.3
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d)|
          expect(a.value).to be_duration(8, unit: :s)
          expect(b.value).to be_duration(9.849155306759329, unit: :s)
          expect(c.value).to be_duration(10.648000000000003, unit: :s)
          expect(d.value).to be_duration(13.489468760533386, unit: :s)
        end
      end
    end

    context 'when the given operator is not defiend' do
      it 'should be raise EvaluationError' do
        node = parse(<<~'PKL')
          a = 1.s || true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for Duration type'

        node = parse(<<~'PKL')
          a = 1.1.s || true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'||\' is not defined for Duration type'

        node = parse(<<~'PKL')
          a = 1.s && true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Duration type'

        node = parse(<<~'PKL')
          a = 1.1.s && true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'operator \'&&\' is not defined for Duration type'
      end
    end

    context 'when the given operand is invalid' do
      it 'should raise EvaluationError' do
        [
          '>', '<', '>=', '<=',
          '+', '-'
        ].each do |op|
        node = parse(<<~PKL)
          a = 1.s #{op} 1
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} 1.0
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} 1
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Int is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} 1.0
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Float is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end

        ['*', '%', '**'].each do |op|
        node = parse(<<~PKL)
          a = 1.s #{op} 2.s
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Duration is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} 2.2.s
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Duration is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} 2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} 2.2.kb
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type DataSize is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end

        ['/', '~/'].each do |op|
        node = parse(<<~PKL)
          a = 1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} true
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type Boolean is given for operator '#{op}'"

        node = parse(<<~PKL)
          a = 1.1.s #{op} "foo"
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error "invalid operand type String is given for operator '#{op}'"
        end
      end
    end
  end

  describe 'builtin property/method' do
    describe 'value' do
      it 'should return the value of this duration' do
        node = parse(<<~'PKL')
          a = 1.ns.value
          b = 2.2.us.value
          c = 3.ms.value
          d = 4.4.s.value
          e = 5.min.value
          f = 6.6.h.value
          g = 7.d.value
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_int(1)
          expect(b.value).to be_float(2.2)
          expect(c.value).to be_int(3)
          expect(d.value).to be_float(4.4)
          expect(e.value).to be_int(5)
          expect(f.value).to be_float(6.6)
          expect(g.value).to be_int(7)
        end
      end
    end

    describe 'unit' do
      it 'should return the unit of this duration' do
        node = parse(<<~'PKL')
          a = 1.ns.unit
          b = 2.2.us.unit
          c = 3.ms.unit
          d = 4.4.s.unit
          e = 5.min.unit
          f = 6.6.h.unit
          g = 7.d.unit
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_evaluated_string('ns')
          expect(b.value).to be_evaluated_string('us')
          expect(c.value).to be_evaluated_string('ms')
          expect(d.value).to be_evaluated_string('s')
          expect(e.value).to be_evaluated_string('min')
          expect(f.value).to be_evaluated_string('h')
          expect(g.value).to be_evaluated_string('d')
        end
      end
    end

    describe 'isPositive' do
      it 'should tell if this duration has a value of zero or greater' do
        node = parse(<<~'PKL')
          a = 0.min.isPositive
          b = 0.0.min.isPositive
          c = 1.min.isPositive
          d = 0.1.min.isPositive
          e = (-0).min.isPositive
          f = (-0.0).min.isPositive
          g = (-1).min.isPositive
          h = (-0.1).min.isPositive
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

    describe 'isoString' do
      it 'should return an ISO 8601 representation of this duration' do
        node = parse(<<~'PKL')
          a = 1.ns.isoString
          b = 2.2.us.isoString
          c = 3.ms.isoString
          d = 4.4.s.isoString
          e = 5.min.isoString
          f = 6.6.h.isoString
          g = 7.d.isoString
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_evaluated_string('PT0.000000001S')
          expect(b.value).to be_evaluated_string('PT0.0000022S')
          expect(c.value).to be_evaluated_string('PT0.003S')
          expect(d.value).to be_evaluated_string('PT4.4S')
          expect(e.value).to be_evaluated_string('PT5M')
          expect(f.value).to be_evaluated_string('PT6H36M')
          expect(g.value).to be_evaluated_string('PT168H')
        end

        node = parse(<<~'PKL')
          a = 2000.5.ms.isoString
          b = 0.h.isoString
          c = 0.0.h.isoString
          d = (-0.0).h.isoString
          e = 0.s.isoString
          f = 0.0.s.isoString
          g = (-0.0).s.isoString
          h = 0.ms.isoString
          i = 0.0.ms.isoString
          j = (-0.0).ms.isoString
          k = 100.d.isoString
          l = (-10.001).s.isoString
          m = (-3.1.h).isoString
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g, h, i, j, k, l, m)|
          expect(a.value).to be_evaluated_string('PT2.0005S')
          expect(b.value).to be_evaluated_string('PT0S')
          expect(c.value).to be_evaluated_string('PT0S')
          expect(d.value).to be_evaluated_string('PT0S')
          expect(e.value).to be_evaluated_string('PT0S')
          expect(f.value).to be_evaluated_string('PT0S')
          expect(g.value).to be_evaluated_string('PT0S')
          expect(h.value).to be_evaluated_string('PT0S')
          expect(i.value).to be_evaluated_string('PT0S')
          expect(j.value).to be_evaluated_string('PT0S')
          expect(k.value).to be_evaluated_string('PT2400H')
          expect(l.value).to be_evaluated_string('-PT10.001S')
          expect(m.value).to be_evaluated_string('-PT3H6M')
        end
      end

      context 'when this duration cannot be converted to ISO 8601 representation' do
        it 'should raise EvaluationError' do
          node = parse(<<~'PKL')
            a = (0/0).s.isoString
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'cannot convert duration \'NaN.s\' to ISO 8601 duration'

          node = parse(<<~'PKL')
            a = (1/0).s.isoString
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'cannot convert duration \'Infinity.s\' to ISO 8601 duration'

          node = parse(<<~'PKL')
            a = (-1/0).s.isoString
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'cannot convert duration \'-Infinity.s\' to ISO 8601 duration'
        end
      end
    end

    describe 'isBetween' do
      it 'should tell if this duration is greater than or equal to start and less than or equal to inclusiveEnd' do
        node = parse(<<~'PKL')
          a = 3.min.isBetween(2.min, 4.min)
          b = 3.min.isBetween(3.min, 4.min)
          c = 3.min.isBetween(2.min, 3.min)
          d = 3.min.isBetween(3.min, 3.min)
          e = 3.min.isBetween(120.s, 180.s)
          f = 3.min.isBetween(1.min, 2.min)
          g = 3.min.isBetween(4.min, 2.min)
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
          a = 3.3.min.isBetween(2.2.min, 4.4.min)
          b = 3.3.min.isBetween(3.3.min, 4.4.min)
          c = 3.3.min.isBetween(2.2.min, 3.3.min)
          d = 3.3.min.isBetween(3.3.min, 3.3.min)
          e = 3.3.min.isBetween(120.s, 210.s)
          f = 3.3.min.isBetween(1.1.min, 2.2.min)
          g = 3.3.min.isBetween(4.4.min, 2.2.min)
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
          a = 1.d.toUnit("d")
          b = 1.d.toUnit("h")
          c = 1.d.toUnit("min")
          d = 1.d.toUnit("s")
          e = 1.d.toUnit("ms")
          f = 1.d.toUnit("us")
          g = 1.d.toUnit("ns")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_duration(1, unit: :d)
          expect(b.value).to be_duration(24, unit: :h)
          expect(c.value).to be_duration(1440, unit: :min)
          expect(d.value).to be_duration(86400, unit: :s)
          expect(e.value).to be_duration(86400000, unit: :ms)
          expect(f.value).to be_duration(86400000000, unit: :us)
          expect(g.value).to be_duration(86400000000000, unit: :ns)
        end

        node = parse(<<~'PKL')
          a = 1.d.toUnit("ns").toUnit("d")
          b = 1.d.toUnit("ns").toUnit("h")
          c = 1.d.toUnit("ns").toUnit("min")
          d = 1.d.toUnit("ns").toUnit("s")
          e = 1.d.toUnit("ns").toUnit("ms")
          f = 1.d.toUnit("ns").toUnit("us")
          g = 1.d.toUnit("ns").toUnit("ns")
        PKL
        node.evaluate(nil).properties.then do |(a, b, c, d, e, f, g)|
          expect(a.value).to be_duration(1, unit: :d)
          expect(b.value).to be_duration(24, unit: :h)
          expect(c.value).to be_duration(1440, unit: :min)
          expect(d.value).to be_duration(86400, unit: :s)
          expect(e.value).to be_duration(86400000, unit: :ms)
          expect(f.value).to be_duration(86400000000, unit: :us)
          expect(g.value).to be_duration(86400000000000, unit: :ns)
        end

        node = parse(<<~'PKL')
          a = 0.5.h.toUnit("s")
          b = 1800.s.toUnit("h")
        PKL
        node.evaluate(nil).properties.then do |(a, b)|
          expect(a.value).to be_duration(1800, unit: :s)
          expect(b.value).to be_duration(0.5, unit: :h)
        end
      end

      context 'when non data unit string is given' do
        it 'should raise EvaluationError' do
          node = parse(<<~'PKL')
            a = 1.d.toUnit("foo")
          PKL
          expect { node.evaluate(nil) }
            .to raise_evaluation_error 'expected value of type ' \
                                       '"ns"|"us"|"ms"|"s"|"min"|"h"|"d", ' \
                                       'but got "foo"'
        end
      end
    end
  end
end
