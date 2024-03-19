# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_module) do
        (
          ws? >> pkl_module_items.as(:items).maybe >> ws?
        ).as(:pkl_module)
      end

      rule(:pkl_module_items) do
        pkl_module_item >> (ws >> pkl_module_item).repeat
      end

      rule(:pkl_module_item) do
        pkl_class_property
      end
    end

    define_transform do
      rule(pkl_module: simple(:_)) do
        Node::PklModule.new(nil, sof_position)
      end

      rule(pkl_module: { items: subtree(:items) }) do
        Array(items)
          .then { Node::PklModule.new(_1, _1.first.position) }
      end
    end
  end
end
