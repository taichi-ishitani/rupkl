# frozen_string_literal: true

module RuPkl
  class Parser
    #
    # Boolean literal
    #
    define_parser do
      rule(:boolean_literal) do
        kw_true.as(:true_value) | kw_false.as(:false_value)
      end
    end

    define_transform do
      rule(true_value: simple(:v)) do
        Node::Boolean.new(true, node_position(v))
      end

      rule(false_value: simple(:v)) do
        Node::Boolean.new(false, node_position(v))
      end
    end
  end
end
