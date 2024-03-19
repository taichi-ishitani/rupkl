# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_object) do
        bracketed(
          pkl_object_members.as(:members).maybe,
          str('{').as(:start), '}'
        ).as(:pkl_object)
      end

      rule(:pkl_object_members) do
        pkl_object_member >> (ws >> pkl_object_member).repeat
      end

      rule(:pkl_object_member) do
        pkl_object_property | pkl_object_element | pkl_object_entry
      end

      rule(:pkl_object_property) do
        (
          id.as(:name) >> ws? >>
            (
              (str('=').ignore >> ws? >> expression.as(:value)) |
              (pkl_object >> (ws? >> pkl_object).repeat).as(:objects)
            )
        ).as(:pkl_object_property)
      end

      rule(:pkl_object_element) do
        expression
      end

      rule(:pkl_object_entry) do
        (
          bracketed(expression.as(:key), '[', ']') >> ws? >>
            (
              (str('=').ignore >> ws? >> expression.as(:value)) |
              (pkl_object >> (ws? >> pkl_object).repeat).as(:objects)
            )
        ).as(:pkl_object_entry)
      end
    end

    define_transform do
      rule(pkl_object: { start: simple(:s) }) do
        Node::PklObject.new(nil, node_position(s))
      end

      rule(pkl_object: { start: simple(:s), members: subtree(:m) }) do
        Node::PklObject.new(Array(m), node_position(s))
      end

      rule(pkl_object_property: { name: simple(:n), value: simple(:v) }) do
        Node::PklObjectProperty.new(n, v, nil, n.position)
      end

      rule(pkl_object_property: { name: simple(:n), objects: subtree(:o) }) do
        Node::PklObjectProperty.new(n, nil, Array(o), n.position)
      end

      rule(pkl_object_entry: { key: simple(:k), value: simple(:v) }) do
        Node::PklObjectEntry.new(k, v, nil, k.position)
      end

      rule(pkl_object_entry: { key: simple(:k), objects: subtree(:o) }) do
        Node::PklObjectEntry.new(k, nil, Array(o), k.position)
      end
    end
  end
end
