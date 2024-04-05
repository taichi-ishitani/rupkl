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
    end

    define_transform do
      rule(class_property: { name: simple(:n), value: simple(:v) }) do
        Node::ObjectProperty.new(n, v, n.position)
      end
    end
  end
end
