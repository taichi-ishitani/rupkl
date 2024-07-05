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

      rule(:primary) do
        [
          float_literal, int_literal, boolean_literal, string_literal,
          this_expression, null_expression, new_expression, amend_expression,
          unqualified_member_ref, parenthesized_expression
        ].inject(:|)
      end

      rule(:qualified_members) do
        (
          ws? >> (str('?.') | str('.')).as(:dot) >> ws? >> id.as(:name)
        ).as(:qualified_member).repeat(1)
      end

      rule(:qualified_member_ref) do
        (
          primary.as(:receiver) >>
            (
              qualified_members.as(:members) >>
                (pure_ws? >> argument_list.as(:arguments)).maybe
            ).repeat(1).as(:member_refs)
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

      rule(:non_null_operation) do
        (
          subscript_operation.as(:operand) >>
            ws? >> str(:'!!').as(:non_null_operator)
        ) | subscript_operation
      end

      rule(:unary_operation) do
        (
          (str(:-) | str(:!)).as(:unary_operator) >>
            ws? >> non_null_operation.as(:operand)
        ) | non_null_operation
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
        qualified_member:
          { dot: simple(:dot), name: simple(:name) }
      ) do
        [name, dot == '?.']
      end

      rule(
        qualified_member_ref:
          {
            receiver: simple(:receiver), member_refs: subtree(:member_refs)
          }
      ) do
        member_refs.inject(receiver) do |r, refs|
          if refs.key?(:arguments)
            process_method_call(r, refs[:members], refs[:arguments])
          else
            process_member_ref(r, refs[:members])
          end
        end
      end

      define_helper(:process_member_ref) do |receiver, members|
        members.inject(receiver) do |r, m|
          name, nullable = m
          Node::MemberReference.new(nil, r, name, nullable, r.position)
        end
      end

      define_helper(:process_method_call) do |receiver, members, arguments|
        r_node = process_member_ref(receiver, members[..-2])
        [r_node, members[-1]].then do |r, m|
          name, nullable = m
          Node::MethodCall.new(nil, r, name, arguments, nullable, name.position)
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
        subscript_operation:
          { receiver: simple(:receiver), key: sequence(:key) }
      ) do
        key.inject(receiver) do |r, k|
          Node::SubscriptOperation.new(nil, :[], r, k, r.position)
        end
      end

      rule(operand: simple(:operand), non_null_operator: simple(:operator)) do
        Node::NonNullOperation.new(nil, operator.to_sym, operand, operand.position)
      end

      rule(unary_operator: simple(:operator), operand: simple(:operand)) do
        Node::UnaryOperation.new(nil, operator.to_sym, operand, node_position(operator))
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
