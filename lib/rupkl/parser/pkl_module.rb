# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:pkl_module) do
        ws? >> pkl_module_items.maybe.as(:pkl_module_items) >> ws?
      end

      rule(:pkl_module_items) do
        (pkl_module_item >> (ws >> pkl_module_item).repeat)
      end

      rule(:pkl_module_item) do
        pkl_class_property.as(:property)
      end
    end

    define_transform do
      rule(pkl_module_items: subtree(:module_items)) do
        items =
          case module_items
          when Hash then module_items.to_a
          when Array then module_items.flat_map(&:to_a)
          end
        pos = items&.dig(0, 0) || sof_position
        Node::PklModule.new(items, pos)
      end
    end
  end
end
