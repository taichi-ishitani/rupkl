# frozen_string_literal: true

module RuPkl
  module ParserHelpers
    def boolean_literal(value)
      be_instance_of(Node::Boolean).and have_attributes(value: value)
    end
  end
end
