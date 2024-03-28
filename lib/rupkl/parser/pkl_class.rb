# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_class_property) do
        (
          id.as(:name) >> ws? >>
          (
            (str('=').ignore >> ws? >> expression.as(:value)) |
            (object >> (ws? >> object).repeat).as(:objects)
          )
        ).as(:class_property)
      end
    end

    define_transform do
      rule(class_property: { name: simple(:n), value: simple(:v) }) do
        Node::PklClassProperty.new(n, v, nil, n.position)
      end
    end

    define_transform do
      rule(class_property: { name: simple(:n), objects: subtree(:o) }) do
        Node::PklClassProperty.new(n, nil, Array(o), n.position)
      end
    end
  end
end
