# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:object) do
        bracketed(
          object_members.as(:members).maybe,
          str('{').as(:start), '}'
        ).as(:object)
      end

      rule(:object_members) do
        object_member >> (ws >> object_member).repeat
      end

      rule(:object_member) do
        object_property | object_entry | object_element
      end

      rule(:object_property) do
        (
          id.as(:name) >> ws? >>
            (
              (str('=').ignore >> ws? >> expression.as(:value)) |
              (object >> (ws? >> object).repeat).as(:objects)
            )
        ).as(:object_property)
      end

      rule(:object_entry) do
        (
          bracketed(expression.as(:key), '[', ']') >> ws? >>
            (
              (str('=').ignore >> ws? >> expression.as(:value)) |
              (object >> (ws? >> object).repeat).as(:objects)
            )
        ).as(:object_entry)
      end

      rule(:object_element) do
        expression
      end
    end

    define_transform do
      rule(object: { start: simple(:s) }) do
        Node::UnresolvedObject.new(nil, node_position(s))
      end

      rule(object: { start: simple(:s), members: subtree(:m) }) do
        Node::UnresolvedObject.new(Array(m), node_position(s))
      end

      rule(object_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(n, v, nil, n.position)
      end

      rule(object_property: { name: simple(:n), objects: subtree(:o) }) do
        Node::ObjectProperty.new(n, nil, Array(o), n.position)
      end

      rule(object_entry: { key: simple(:k), value: simple(:v) }) do
        Node::ObjectEntry.new(k, v, nil, k.position)
      end

      rule(object_entry: { key: simple(:k), objects: subtree(:o) }) do
        Node::ObjectEntry.new(k, nil, Array(o), k.position)
      end
    end
  end
end
