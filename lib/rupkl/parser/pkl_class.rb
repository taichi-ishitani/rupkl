# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_class_property) do
        id.as(:class_property_name) >> ws? >>
          str('=') >> ws? >> expression.as(:value)
      end
    end

    define_transform do
      rule(class_property_name: simple(:name), value: simple(:value)) do
        Node::PklClassProperty.new(name, value, name.position)
      end
    end
  end
end
