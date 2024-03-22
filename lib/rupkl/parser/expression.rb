# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:primary) do
        [
          float_literal, integer_literal, boolean_literal, string_literal,
          bracketed(expression)
        ].inject(:|)
      end

      rule(:unary_operation) do
        (
          (str(:-) | str(:!)).as(:unary_operator) >> ws? >> primary.as(:operand)
        ) | primary
      end

      rule(:binary_operation) do
        expression = unary_operation
        operators = binary_operators
        reducer = proc { |l, o, r| { binary_operator: o, l_operand: l, r_operand: r } }
        infix_expression(expression, *operators, &reducer) | unary_operation
      end

      rule(:expression) do
        binary_operation
      end

      private

      def binary_operators
        operators = {
          '||': 1, '&&': 2,
          '==': 3, '!=': 3,
          '<': 4, '>': 4, '<=': 4, '>=': 4,
          '+': 5, '-': 5,
          '*': 6, '/': 6, '~/': 6, '%': 6,
          '**': 7
        }
        operators
          .sort_by { |op, _| op.length }.reverse
          .map { |op, priority| binary_operator_element(op, priority) }
      end

      def binary_operator_element(operator, priority)
        atom =
          if operator == :-
            pure_ws? >> str(operator) >> ws?
          else
            ws? >> str(operator) >> ws?
          end
        if operator == :**
          [atom, priority, :right]
        else
          [atom, priority, :left]
        end
      end
    end

    define_transform do
      rule(unary_operator: simple(:operator), operand: simple(:operand)) do
        Node::UnaryOperation.new(operator.to_sym, operand, node_position(operator))
      end

      rule(
        binary_operator: simple(:operator),
        l_operand: simple(:l_operand), r_operand: simple(:r_operand)
      ) do
        Node::BinaryOperation.new(
          operator.to_sym, l_operand, r_operand, l_operand.position
        )
      end
    end
  end
end
