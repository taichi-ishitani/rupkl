# frozen_string_literal: true

RSpec.describe RuPkl::Node::MemberReference do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe '#evaluate' do
    it 'should return the specified member' do
      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar = foo
      PKL
      node.evaluate(nil).properties[-1]
        .then { |m| expect(m.value).to be_int(1) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo {
          bar = 2
        }
        baz = foo.bar
      PKL
      node.evaluate(nil).properties[-1]
        .then { |m| expect(m.value).to be_int(2) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo {
          bar {
            baz = 3
          }
        }
        baz = foo.bar.baz
      PKL
      node.evaluate(nil).properties[-1]
        .then { |m| expect(m.value).to be_int(3) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar {
          baz = foo
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[0]
        .then { |m| expect(m.value).to be_int(1) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo_0 {
          bar_0 {
            baz_0 = 3
          }
        }
        foo_1 {
          bar_1 = foo_0.bar_0.baz_0
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[0]
        .then { |m| expect(m.value).to be_int(3) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo {
          bar_0 {
            baz_0 = 3
          }
          bar_1 {
            baz_1 = bar_0.baz_0
          }
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[-1].value.properties[-1]
        .then { |m| expect(m.value).to be_int(3) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar {
          baz = foo
          foo = 2
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[0]
        .then { |m| expect(m.value).to be_int(2) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar {
          bar = foo
          foo = 2
        }{
          foo = 3
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[0]
        .then { |m| expect(m.value).to be_int(3) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar {
          bar = foo
        }{
          foo = 3
        }
      PKL
      node.evaluate(nil).properties[-1].value.properties[0]
        .then { |m| expect(m.value).to be_int(1) }

      node = parser.parse(<<~'PKL', root: :pkl_module)
        foo = 1
        bar = foo + 1
        baz = bar + 1
      PKL
      node.evaluate(nil).properties[-1]
        .then { |m| expect(m.value).to be_int(3) }
    end

    context 'when the given member is not found' do
      it 'should raise EvaluationError' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo = 1
          bar = baz
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find property \'baz\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            bar = 1
          }
          bar = foo.baz
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find property \'baz\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            bar {
              baz = 1
            }
          }
          bar = foo.bar.qux
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find property \'qux\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo = 1
          bar {
            baz = qux
          }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find property \'qux\''

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            bar_0 {
              baz_0 = 1
            }
            bar_1 {
              baz_0 = bar_0.qux_0
            }
          }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'cannot find property \'qux_0\''
      end
    end

    context 'when the given member refers itself' do
      it 'should raise EvaluationError' do
        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo = foo
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'circular reference is detected'

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo = bar
          bar = foo
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'circular reference is detected'

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            bar = foo.bar
          }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'circular reference is detected'

        node = parser.parse(<<~'PKL', root: :pkl_module)
          foo {
            bar {
              baz = foo.bar.baz
            }
          }
        PKL
        expect { node.evaluate(nil) }
          .to raise_evaluation_error 'circular reference is detected'
      end
    end
  end
end
