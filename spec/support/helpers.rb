# frozen_string_literal: true

module RuPkl
  module Helpers
    def boolean_literal(value)
      be_instance_of(Node::Boolean).and have_attributes(value: value)
    end

    def integer_literal(value)
      be_instance_of(Node::Integer).and have_attributes(value: value)
    end

    def string_literal(*portions)
      be_instance_of(Node::String).and have_attributes(portions: portions)
    end

    alias_method :ss_literal, :string_literal

    def ms_literal(*portions)
      portions_processed =
        portions.flat_map do |portion|
          case portion
          when String
            portion.chomp.each_line.flat_map { _1.partition("\n").reject(&:empty?) }
          else
            portion
          end
        end
      be_instance_of(Node::String).and have_attributes(portions: portions_processed)
    end

    def empty_string_literal
      be_instance_of(Node::String).and have_attributes(portions: be_nil)
    end

    def be_evaluated_string(string)
      be_instance_of(Node::String).and have_attributes(value: string, portions: be_nil)
    end

    def identifer(id)
      be_instance_of(Node::Identifier).and have_attributes(id: id.to_sym)
    end

    def expression_matcher(expression)
      case expression
      when TrueClass, FalseClass then boolean_literal(expression)
      when Integer then integer_literal(expression)
      when String then string_literal(expression)
      else expression
      end
    end

    def u_op(operator, operand)
      be_instance_of(Node::UnaryOperation)
        .and have_attributes(operator: operator, operand: expression_matcher(operand))
    end

    def b_op(operator, l_operand, r_operand)
      l_matcher = expression_matcher(l_operand)
      r_matcher = expression_matcher(r_operand)
      be_instance_of(Node::BinaryOperation)
        .and have_attributes(operator: operator, l_operand: l_matcher, r_operand: r_matcher)
    end

    PklClassProperty = Struct.new(:name, :value) do
      def to_matcher(context)
        context.instance_exec(name, value) do |n, v|
          be_instance_of(Node::PklClassProperty)
            .and have_attributes(name: identifer(n), value: expression_matcher(v))
        end
      end
    end

    PklModule = Struct.new(:properties) do
      def property(name, value)
        self.properties ||= []
        self.properties << PklClassProperty.new(name, value)
      end

      def to_matcher(context)
        properties_matcher = create_properties_matcher(context)
        context.instance_exec do
          be_instance_of(Node::PklModule)
            .and have_attributes(properties: properties_matcher )
        end
      end

      private

      def create_properties_matcher(context)
        if self.properties.nil?
          context.instance_exec { be_nil }
        else
          self.properties
            .map { _1.to_matcher(context) }
            .then { |m| context.instance_exec { match(m) } }
        end
      end
    end

    def pkl_module
      m = PklModule.new
      yield(m) if block_given?
      m.to_matcher(self)
    end

    alias_method :be_pkl_module, :pkl_module

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end
  end
end
