# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:object) do
        (object_body >> (ws? >> object_body).repeat).as(:bodies).as(:object)
      end

      rule(:object_body) do
        bracketed(
          object_items.as(:items).maybe,
          str('{').as(:body_begin), '}'
        ).as(:object_body)
      end

      rule(:object_items) do
        object_item >> (ws >> object_item).repeat
      end

      rule(:object_item) do
        [
          when_generator, object_method, object_element,
          object_property, object_entry
        ].inject(:|)
      end

      rule(:object_property) do
        (
          modifiers.as(:modifiers).maybe >> id.as(:name) >> ws? >>
            ((str('=').ignore >> ws? >> expression) | object).as(:value)
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
          modifiers.absent? >> expression >> (ws? >> match('[={]')).absent?
        ).as(:object_element)
      end

      rule(:object_method) do
        (
          method_header >> ws? >>
          str('=').ignore >> ws? >> expression.as(:body)
        ).as(:object_method)
      end

      rule(:when_generator) do
        (
          kw_when.as(:kw_when) >> ws? >>
          bracketed(expression.as(:condition), '(', ')') >> ws? >>
          object_body.as(:when_body) >>
          (ws? >> kw_else.ignore >> ws? >> object_body.as(:else_body)).maybe
        ).as(:when_generator)
      end
    end

    define_transform do
      rule(object: { bodies: subtree(:b) }) do
        bodies = Array(b)
        Node::UnresolvedObject.new(nil, nil, bodies, bodies.first.position)
      end

      rule(object_body: { body_begin: simple(:body_begin) }) do
        Node::ObjectBody.new(nil, nil, node_position(body_begin))
      end

      rule(
        object_body: {
          body_begin: simple(:body_begin), items: subtree(:items)
        }
      ) do
        Node::ObjectBody.new(nil, Array(items), node_position(body_begin))
      end

      rule(object_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(nil, n, v, nil, n.position)
      end

      rule(
        object_property:
          {
            modifiers: subtree(:m), name: simple(:n), value: simple(:v)
          }
      ) do
        Node::ObjectProperty.new(nil, n, v, m, n.position)
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

      rule(
        when_generator:
          {
            kw_when: simple(:kw), condition: simple(:condition),
            when_body: simple(:when_body)
          }
      ) do
        Node::WhenGenerator.new(
          nil, condition, when_body, nil, nil, node_position(kw)
        )
      end

      rule(
        when_generator:
          {
            kw_when: simple(:kw), condition: simple(:condition),
            when_body: simple(:when_body), else_body: simple(:else_body)
          }
      ) do
        Node::WhenGenerator.new(
          nil, condition, when_body, else_body, nil, node_position(kw)
        )
      end
    end
  end
end
