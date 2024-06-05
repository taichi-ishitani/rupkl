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
        [
          object_method, object_element,
          object_property, object_entry
        ].inject(:|)
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
        (
          expression >> (ws? >> match('[={]')).absent?
        ).as(:object_element)
      end

      rule(:object_method) do
        (
          method_header >> ws? >>
          str('=').ignore >> ws? >> expression.as(:body)
        ).as(:object_method)
      end
    end

    define_transform do
      rule(object: { bodies: subtree(:b) }) do
        bodies = Array(b)
        Node::UnresolvedObject.new(nil, nil, bodies, bodies.first.position)
      end

      rule(object_body: { body_begin: simple(:b) }) do
        Node::ObjectBody.new(nil, nil, node_position(b))
      end

      rule(object_body: { body_begin: simple(:b), members: subtree(:m) }) do
        Node::ObjectBody.new(nil, Array(m), node_position(b))
      end

      rule(object_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(nil, n, v, n.position)
      end

      rule(object_entry: { key: simple(:k), value: simple(:v) }) do
        Node::ObjectEntry.new(nil, k, v, k.position)
      end

      rule(object_element: simple(:e)) do
        Node::ObjectElement.new(nil, e, e.position)
      end

      rule(
        object_method:
          {
            kw_function: simple(:kw), name: simple(:name),
            params: subtree(:params), body: simple(:body)
          }
      ) do
        Node::MethodDefinition.new(nil, name, params, nil, body, node_position(kw))
      end

      rule(
        object_method:
          {
            kw_function: simple(:kw), name: simple(:name),
            params: subtree(:params), type: simple(:type), body: simple(:body)
          }
      ) do
        Node::MethodDefinition.new(nil, name, params, type, body, node_position(kw))
      end
    end
  end
end
