# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_class_property) do
        (
          id.as(:name) >> ws? >>
          (
            (str('=').ignore >> ws? >> expression) | object
          ).as(:value)
        ).as(:class_property)
      end

      rule(:pkl_class_method) do
        (
          method_header >> ws? >>
          str('=').ignore >> ws? >> expression.as(:body)
        ).as(:pkl_class_method)
      end
    end

    define_transform do
      rule(class_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(nil, n, v, n.position)
      end

      rule(
        pkl_class_method:
          {
            kw_function: simple(:kw), name: simple(:name),
            params: subtree(:params), body: simple(:body)
          }
      ) do
        Node::MethodDefinition.new(nil, name, params, body, node_position(kw))
      end
    end
  end
end
