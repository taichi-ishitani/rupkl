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

    alias_method :ss_literal, :string_literal

    def ms_literal(*portions)
      portions_processed =
        portions.flat_map do |portion|
          case portion
          when String
            portion.chomp.each_line.flat_map { _1.partition("\n").reject(&:empty?) }
          else
            portion
          end
        end
      be_instance_of(Node::String).and have_attributes(portions: portions_processed)
    end

    def empty_string_literal
      be_instance_of(Node::String).and have_attributes(portions: be_nil)
    end
  end
end
