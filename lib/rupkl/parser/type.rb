# frozen_string_literal: true

module RuPkl
  class Parser
    define_parser do
      rule(:declared_type) do
        id.as(:type).as(:declared_type)
      end

      rule(:type) do
        declared_type
      end
    end

    define_transform do
      rule(
        declared_type:
          { type: simple(:t) }
      ) do
        Node::DeclaredType.new(nil, Array(t), t.position)
      end
    end
  end
end
