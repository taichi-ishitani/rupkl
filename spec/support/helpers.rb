# frozen_string_literal: true

module RuPkl
  module ParserHelpers
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

    def identifer(id)
      be_instance_of(Node::Identifier).and have_attributes(id: id)
    end

    def operand_matcher(operand)
      case operand
      when TrueClass, FalseClass then boolean_literal(operand)
      when Integer then integer_literal(operand)
      else operand
      end
    end

    def u_op(operator, operand)
      be_instance_of(Node::UnaryOperation)
        .and have_attributes(operator: operator, operand: operand_matcher(operand))
    end

    def b_op(operator, l_operand, r_operand)
      l_matcher = operand_matcher(l_operand)
      r_matcher = operand_matcher(r_operand)
      be_instance_of(Node::BinaryOperation)
        .and have_attributes(operator: operator, l_operand: l_matcher, r_operand: r_matcher)
    end

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end
  end
end
