# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:primary) do
        boolean_literal | integer_literal | string_literal
      end

      rule(:unary_operation) do
        (
          (str(:-) | str(:!)).as(:unary_operator) >> ws? >> primary.as(:operand)
        ) | primary
      end

      rule(:expression) do
        unary_operation
      end
    end

    define_transform do
      rule(unary_operator: simple(:operator), operand: simple(:operand)) do
        Node::UnaryOperation.new(operator.to_sym, operand, node_position(operator))
      end
    end
  end
end
