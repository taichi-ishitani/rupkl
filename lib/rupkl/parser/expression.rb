# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:argument_list) do
        bracketed(list(expression).maybe, '(', ')').as(:argument_list)
      end

      rule(:unqualified_member_ref) do
        (
          id.as(:name) >>
            (pure_ws? >> argument_list.as(:arguments)).maybe
        ).as(:unqualified_member_ref)
      end

      rule(:parenthesized_expression) do
        bracketed(expression)
      end

      rule(:this_expression) do
        kw_this.as(:this_expression)
      end

      rule(:null_expression) do
        kw_null.as(:null_expression)
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

      rule(:if_expression) do
        (
          kw_if.as(:kw_if) >> ws? >>
            bracketed(expression.as(:condition), '(', ')') >> ws? >>
              expression.as(:if_expression) >> ws >>
            kw_else.ignore >> ws >>
              expression.as(:else_expression)
        ).as(:if_expression)
      end

      rule(:primary) do
        [
          float_literal, int_literal, boolean_literal, string_literal,
          this_expression, null_expression, new_expression, amend_expression,
          if_expression, unqualified_member_ref, parenthesized_expression
        ].inject(:|)
      end

      rule(:qualifier) do
        (str('?.') | str('.'))
      end

      rule(:qualified_member_ref) do
        (
          ws? >> qualifier.as(:qualifier) >> ws? >>
            id.as(:member) >> (pure_ws? >> argument_list.as(:arguments)).maybe
        ).as(:qualified_member_ref)
      end

      rule(:subscript_key) do
        (
          pure_ws? >> bracketed(expression, '[', ']') >>
            (ws? >> str('=')).absent?
        ).as(:subscript_key)
      end

      rule(:qualified_member_ref_or_subscript_operation) do
        (
          primary.as(:receiver) >>
            (
              qualified_member_ref | subscript_key
            ).repeat(1).as(:member_ref_or_subscript_key)
        ).as(:qualified_member_ref_or_subscript_operation) | primary
      end

      rule(:non_null_operation) do
        (
          qualified_member_ref_or_subscript_operation.as(:operand) >>
            ws? >> str(:'!!').as(:non_null_operator)
        ) | qualified_member_ref_or_subscript_operation
      end

      rule(:unary_operator) do
        (str('-') | str('!')).as(:unary_operator)
      end

      rule(:unary_operation) do
        (
          (unary_operator >> ws?).repeat(1).as(:operators) >>
            non_null_operation.as(:operand)
        ).as(:unary_operation) | non_null_operation
      end

      rule(:binary_operation) do
        expression = unary_operation
        operators = binary_operators
        reducer = proc { |l, o, r| { binary_operator: o, l_operand: l, r_operand: r } }
        infix_expression(expression, *operators, &reducer)
      end

      rule(:expression) do
        binary_operation
      end

      private

      def binary_operators
        operators = {
          '??': 1,
          '||': 2, '&&': 3,
          '==': 4, '!=': 4,
          '<': 5, '>': 5, '<=': 5, '>=': 5,
          '+': 6, '-': 6,
          '*': 7, '/': 7, '~/': 7, '%': 7,
          '**': 8
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
        associativity =
          (operator in :** | :'??') && :right || :left
        [atom, priority, associativity]
      end
    end

    define_transform do
      rule(argument_list: subtree(:arguments)) do
        arguments == '' ? nil : Array(arguments)
      end

      rule(
        unqualified_member_ref:
          { name: simple(:name) }
      ) do
        Node::MemberReference.new(nil, nil, name, false, name.position)
      end

      rule(
        unqualified_member_ref:
          { name: simple(:name), arguments: subtree(:arguments) }
      ) do
        Node::MethodCall.new(nil, nil, name, arguments, false, name.position)
      end

      rule(
        qualified_member_ref_or_subscript_operation:
          {
            receiver: simple(:receiver),
            member_ref_or_subscript_key: subtree(:member_ref_or_subscript_key)
          }
      ) do
        member_ref_or_subscript_key.inject(receiver) do |r, ref_or_key|
          if ref_or_key.key?(:subscript_key)
            process_subscript_operation(r, ref_or_key[:subscript_key])
          else
            process_member_ref(r, ref_or_key[:qualified_member_ref])
          end
        end
      end

      define_helper(:process_subscript_operation) do |receiver, key|
        Node::SubscriptOperation.new(nil, :[], receiver, key, receiver.position)
      end

      define_helper(:process_member_ref) do |receiver, member_ref|
        nullable = member_ref[:qualifier] == '?.'
        if member_ref.key?(:arguments)
          Node::MethodCall.new(
            nil, receiver, member_ref[:member], member_ref[:arguments],
            nullable, receiver.position
          )
        else
          Node::MemberReference.new(
            nil, receiver, member_ref[:member], nullable, receiver.position
          )
        end
      end

      rule(this_expression: simple(:this)) do
        Node::This.new(nil, node_position(this))
      end

      rule(null_expression: simple(:null)) do
        Node::Null.new(nil, node_position(null))
      end

      rule(
        new_expression:
          { kw_new: simple(:n), bodies: subtree(:b) }
      ) do
        Node::UnresolvedObject.new(nil, nil, b, node_position(n))
      end

      rule(
        new_expression:
          { kw_new: simple(:n), type: simple(:t), bodies: subtree(:b) }
      ) do
        Node::UnresolvedObject.new(nil, t, b, node_position(n))
      end

      rule(
        amend_expression:
          { target: simple(:t), bodies: subtree(:b) }
      ) do
        Node::AmendExpression.new(nil, t, Array(b), t.position)
      end

      rule(
        if_expression:
          {
            kw_if: simple(:kw), condition: simple(:condition),
            if_expression: simple(:if_expression),
            else_expression: simple(:else_expression)
          }
      ) do
        Node::IfExpression.new(
          nil, condition, if_expression, else_expression, node_position(kw)
        )
      end

      rule(operand: simple(:operand), non_null_operator: simple(:operator)) do
        Node::NonNullOperation.new(nil, operator.to_sym, operand, operand.position)
      end

      rule(unary_operator: simple(:op)) do
        op
      end

      rule(
        unary_operation: {
          operators: sequence(:operators), operand: simple(:operand)
        }
      ) do
        operators.reverse.inject(operand) do |result, operator|
          Node::UnaryOperation.new(nil, operator.to_sym, result, node_position(operator))
        end
      end

      rule(
        binary_operator: simple(:operator),
        l_operand: simple(:l_operand), r_operand: simple(:r_operand)
      ) do
        klass =
          case operator.to_sym
          when :'??' then Node::NullCoalescingOperation
          else Node::BinaryOperation
          end
        klass.new(nil, operator.to_sym, l_operand, r_operand, l_operand.position)
      end
    end
  end
end
