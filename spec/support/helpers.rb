# frozen_string_literal: true

module RuPkl
  module ParserHelpers
    def boolean_literal(value)
      be_instance_of(Node::Boolean).and have_attributes(value: value)
    end

    def integer_literal(value)
      be_instance_of(Node::Integer).and have_attributes(value: value)
    end

    def string_literal(*portions)
      be_instance_of(Node::String).and have_attributes(portions: portions)
    end

    def empty_string_literal
      be_instance_of(Node::String).and have_attributes(portions: be_nil)
    end
  end
end
