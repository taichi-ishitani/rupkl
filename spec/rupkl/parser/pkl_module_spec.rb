# frozen_string_literal: true

RSpec.describe RuPkl::Parser do
  let(:parser) do
    RuPkl::Parser.new
  end

  describe 'pkl module' do
    def parse(string)
      parse_string(string, :pkl_module)
    end

    it 'should be parsed by module parser' do
      pkl = <<~'PKL'
      PKL
      expect(parser).to parse(pkl).as(pkl_module)

      pkl = <<~'PKL'



      PKL
      expect(parser).to parse(pkl).as(pkl_module)

      pkl = 'name="Pkl: Configure your Systems in New Ways"'
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :name, 'Pkl: Configure your Systems in New Ways'
        end
      )

      pkl = 'name="Pkl: Configure your Systems in New Ways";attendants=100'
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :name, 'Pkl: Configure your Systems in New Ways'
          m.property :attendants, 100
        end
      )

      pkl = 'name="Pkl: Configure your Systems in New Ways";attendants=100;isInteractive=true'
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :name, 'Pkl: Configure your Systems in New Ways'
          m.property :attendants, 100
          m.property :isInteractive, true
        end
      )

      pkl = <<~'PKL'

        name = "Pkl: Configure your Systems in New Ways"
        attendants = 100
        isInteractive = true

      PKL
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :name, 'Pkl: Configure your Systems in New Ways'
          m.property :attendants, 100
          m.property :isInteractive, true
        end
      )

      pkl = <<~'PKL'
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
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :mixedObject, (
            unresolved_object do |o1|
              o1.body do |b1|
                b1.property :name, 'Pigeon'
                b1.property :lifespan, 8
                b1.element 'wing'
                b1.element 'claw'
                b1.entry 'wing', 'Not related to the _element_ "wing"'
                b1.element 42
                b1.property :extinct, false
                b1.entry false, (
                  unresolved_object do |o2|
                    o2.body { |b2| b2.property :description, 'Construed object example' }
                  end
                )
              end
            end
          )
        end
      )

      pkl = <<~'PKL'
        local foo = 1
        local local bar = 2
      PKL
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.property :foo, 1, local: true
          m.property :bar, 2, local: true
        end
      )

      pkl = <<~'PKL'
        function foo() = a * b * c
        function bar(a) = a * b * c
        function baz(a, b) = a * b * c
        function qux(a, b, c) = a * b * c
      PKL
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.method(:foo, body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
          m.method(:bar, params: [param(:a)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
          m.method(:baz, params: [param(:a), param(:b)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
          m.method(:qux, params: [param(:a), param(:b), param(:c)], body: b_op(:*, b_op(:*, member_ref(:a), member_ref(:b)), member_ref(:c)))
        end
      )

      pkl = <<~'PKL'
        function sum1(a: Int, b: Int): Int = a + b
        function sum2(a: Number, b: Number): Number = a + b
        function sum3(a: Int, b: Int): Int = 1.1
      PKL
      expect(parser).to parse(pkl).as(
        pkl_module do |m|
          m.method(
            :sum1, params: [param(:a, declared_type(:Int)), param(:b, declared_type(:Int))],
            type: declared_type(:Int), body: b_op(:+, member_ref(:a),  member_ref(:b))
          )
          m.method(
            :sum2, params: [param(:a, declared_type(:Number)), param(:b, declared_type(:Number))],
            type: declared_type(:Number), body: b_op(:+, member_ref(:a),  member_ref(:b))
          )
          m.method(
            :sum3, params: [param(:a, declared_type(:Int)), param(:b, declared_type(:Int))],
            type: declared_type(:Int), body: be_float(1.1)
          )
        end
      )
    end
  end
end
