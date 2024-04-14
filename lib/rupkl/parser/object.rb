# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:object) do
        (object_body >> (ws? >> object_body).repeat).as(:bodies).as(:object)
      end

      rule(:object_body) do
        members = object_member >> (ws >> object_member).repeat
        bracketed(
          members.as(:members).maybe,
          str('{').as(:body_begin), '}'
        ).as(:object_body)
      end

      rule(:object_member) do
        object_element | object_property | object_entry
      end

      rule(:object_property) do
        (
          id.as(:name) >> ws? >>
            (
              (str('=').ignore >> ws? >> expression) | object
            ).as(:value)
        ).as(:object_property)
      end

      rule(:object_entry) do
        (
          bracketed(expression.as(:key), '[', ']') >> ws? >>
            (
              (str('=').ignore >> ws? >> expression) | object
            ).as(:value)
        ).as(:object_entry)
      end

      rule(:object_element) do
        expression >> (ws? >> match('[={]')).absent?
      end
    end

    define_transform do
      rule(object: { bodies: subtree(:b) }) do
        bodies = Array(b)
        Node::UnresolvedObject.new(nil, bodies, bodies.first.position)
      end

      rule(object_body: { body_begin: simple(:b) }) do
        Node::ObjectBody.new(nil, node_position(b))
      end

      rule(object_body: { body_begin: simple(:b), members: subtree(:m) }) do
        Node::ObjectBody.new(Array(m), node_position(b))
      end

      rule(object_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(n, v, n.position)
      end

      rule(object_entry: { key: simple(:k), value: simple(:v) }) do
        Node::ObjectEntry.new(k, v, k.position)
      end
    end
  end
end
