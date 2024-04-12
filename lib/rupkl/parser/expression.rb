# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:unqualified_member_ref) do
        id.as(:unqualified_member_ref)
      end

      rule(:parenthesized_expression) do
        bracketed(expression)
      end

      rule(:new_expression) do
        (
          kw_new.as(:kw_new) >>
            (ws? >> type.as(:type)).maybe >>
            (ws? >> object_body).repeat(1).as(:bodies)
        ).as(:new_expression)
      end

      rule(:amend_expression) do
        (
          parenthesized_expression.as(:target) >>
            (ws? >> object_body).repeat(1).as(:bodies)
        ).as(:amend_expression)
      end

      rule(:primary) do
        [
          float_literal, int_literal, boolean_literal, string_literal,
          new_expression, amend_expression, unqualified_member_ref,
          parenthesized_expression
        ].inject(:|)
      end

      rule(:qualified_member_ref) do
        (
          primary.as(:receiver) >>
            (ws? >> str('.') >> ws? >> id).repeat(1).as(:member)
        ).as(:qualified_member_ref) | primary
      end

      rule(:subscript_operation) do
        (
          qualified_member_ref.as(:receiver) >>
            (
              pure_ws? >> bracketed(expression, '[', ']') >>
                (ws? >> str('=')).absent?
            ).repeat(1).as(:key)
        ).as(:subscript_operation) | qualified_member_ref
      end

      rule(:unary_operation) do
        (
          (str(:-) | str(:!)).as(:unary_operator) >>
            ws? >> subscript_operation.as(:operand)
        ) | subscript_operation
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
      rule(unqualified_member_ref: simple(:member)) do
        Node::MemberReference.new(nil, member, member.position)
      end

      rule(
        qualified_member_ref:
          { receiver: simple(:receiver), member: sequence(:member) }
      ) do
        member.inject(receiver) do |r, m|
          Node::MemberReference.new(r, m, r.position)
        end
      end

      rule(
        new_expression:
          { kw_new: simple(:n), bodies: subtree(:b) }
      ) do
        Node::UnresolvedObject.new(nil, b, node_position(n))
      end

      rule(
        new_expression:
          { kw_new: simple(:n), type: simple(:t), bodies: subtree(:b) }
      ) do
        Node::UnresolvedObject.new(t, b, node_position(n))
      end

      rule(
        amend_expression:
          { target: simple(:t), bodies: subtree(:b) }
      ) do
        Node::AmendExpression.new(t, Array(b), t.position)
      end

      rule(
        subscript_operation:
          { receiver: simple(:receiver), key: sequence(:key) }
      ) do
        key.inject(receiver) do |r, k|
          Node::SubscriptOperation.new(r, k, r.position)
        end
      end

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
