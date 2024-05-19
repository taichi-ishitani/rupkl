# frozen_string_literal: true

RSpec.describe RuPkl::Node::MethodCall do
  let(:parser) do
    RuPkl::Parser.new
  end

  def parse(string)
    parser.parse(string.chomp, root: :pkl_module).evaluate(nil)
  end

  describe '#evaluate' do
    it 'should be evaluate the given method' do
      pkl = <<~'PKL'
        a = foo()
        b = this.foo()
        c = 1
        d = 2
        e = 3
        function foo() = c * d * this.e
      PKL
      parse(pkl).properties[..1].then do |(n1, n2)|
        expect(n1.value).to be_int(6)
        expect(n2.value).to be_int(6)
      end

      pkl = <<~'PKL'
        a = foo(4)
        b = this.foo(5)
        d = 2
        e = 3
        function foo(c) = c * d * this.e
      PKL
      parse(pkl).properties[..1].then do |(n1, n2)|
        expect(n1.value).to be_int(24)
        expect(n2.value).to be_int(30)
      end

      pkl = <<~'PKL'
        a = foo(1, 2)
        b = this.foo(4, 5)
        e = 3
        function foo(c, d) = c * d * this.e
      PKL
      parse(pkl).properties[..1].then do |(n1, n2)|
        expect(n1.value).to be_int(6)
        expect(n2.value).to be_int(60)
      end

      #pkl = <<~'PKL'
      #  k = 3
      #  v = 4
      #  a = foo(1, 2, 3)
      #  function foo(a, b, c) = new Dynamic {
      #    c = 2
      #    [a] = b * c
      #    [k] = v
      #  }
      #PKL
      #parse(pkl).properties[-1].then do |n|
      #  expect(n.value).to be_mapping do |m|
      #    m[1] = 2
      #    m[3] = 4
      #  end
      #end

      pkl = <<~'PKL'
        function foo() = b * c * this.d
        b = 1
        c = 2
        d = 3
        e {
          a = foo()
          b = 2
          c = 3
          d = 4
        }
      PKL
      parse(pkl).properties[-1].value.properties[0].then do |n|
        expect(n.value).to be_int(6)
      end
    end

    context 'the given method is not found' do
      it 'should raise EvaluationError' do
        pkl = <<~'PKL'
          a = foo()
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot find method \'foo\''

        pkl = <<~'PKL'
          a = this.foo();
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot find method \'foo\''

        pkl = <<~'PKL'
          a {
            b = foo()
          }
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error 'cannot find method \'foo\''
      end
    end

    context 'when argument arity is not matched' do
      it 'should raise EvaluationError' do
        pkl = <<~'PKL'
          function foo() = 1
          bar = foo(1)
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 0 method arguments but got 1"

        pkl = <<~'PKL'
          function foo(a) = 1
          bar = foo()
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 1 method arguments but got 0"

        pkl = <<~'PKL'
          function foo(a) = 1
          bar = foo(1, 2)
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 1 method arguments but got 2"

        pkl = <<~'PKL'
          function foo(a, b) = 1
          bar = foo()
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 2 method arguments but got 0"

        pkl = <<~'PKL'
          function foo(a, b) = 1
          bar = foo(1)
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 2 method arguments but got 1"

        pkl = <<~'PKL'
          function foo(a, b) = 1
          bar = foo(1, 2, 3)
        PKL
        expect { parse(pkl) }
          .to raise_evaluation_error "expected 2 method arguments but got 3"
      end
    end
  end
end
