# frozen_string_literal: true

module RuPkl
  module Helpers
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

    def be_evaluated_string(string)
      be_instance_of(Node::String).and have_attributes(value: string, portions: be_nil)
    end

    def identifer(id)
      be_instance_of(Node::Identifier).and have_attributes(id: id.to_sym)
    end

    def expression_matcher(expression)
      case expression
      when TrueClass, FalseClass then boolean_literal(expression)
      when Integer then integer_literal(expression)
      when String then string_literal(expression)
      else expression
      end
    end

    def u_op(operator, operand)
      be_instance_of(Node::UnaryOperation)
        .and have_attributes(operator: operator, operand: expression_matcher(operand))
    end

    def b_op(operator, l_operand, r_operand)
      l_matcher = expression_matcher(l_operand)
      r_matcher = expression_matcher(r_operand)
      be_instance_of(Node::BinaryOperation)
        .and have_attributes(operator: operator, l_operand: l_matcher, r_operand: r_matcher)
    end

    PklClassProperty = Struct.new(:name, :value, :objects) do
      def to_matcher(context)
        context.instance_exec(name, value, objects) do |n, v, o|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          object_matcher =
            o&.map { expression_matcher(_1) }&.then { match(_1) } || be_nil
          be_instance_of(Node::PklClassProperty)
            .and have_attributes(name: identifer(n), value: value_matcher, objects: object_matcher)
        end
      end
    end

    PklModule = Struct.new(:properties) do
      def property(name, value_or_objects)
        (self.properties ||= []) <<
          case value_or_objects
          when Array then PklClassProperty.new(name, nil, value_or_objects)
          else PklClassProperty.new(name, value_or_objects, nil)
          end
      end

      def to_matcher(context)
        context.instance_exec(self) do |m|
          be_instance_of(Node::PklModule)
            .and have_attributes(
              properties: m.properties_matcher(self)
            )
        end
      end

      def properties_matcher(context)
        if self.properties.nil?
          context.__send__(:be_nil)
        else
          self.properties
            .map { _1.to_matcher(context) }
            .then { |m| context.__send__(:match, m) }
        end
      end
    end

    def pkl_module
      m = PklModule.new
      yield(m) if block_given?
      m.to_matcher(self)
    end

    alias_method :be_pkl_module, :pkl_module

    PklObjectProperty = Struct.new(:name, :value, :objects) do
      def to_matcher(context)
        context.instance_exec(name, value, objects) do |n, v, o|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          object_matcher =
            o&.map { expression_matcher(_1) }&.then { match(_1) } || be_nil
          be_instance_of(Node::PklObjectProperty)
            .and have_attributes(name: identifer(n), value: value_matcher, objects: object_matcher)
        end
      end
    end

    PklObjectElement = Struct.new(:value) do
      def to_matcher(context)
        context.__send__(:expression_matcher, value)
      end
    end

    PklObjectEntry = Struct.new(:key, :value, :objects) do
      def to_matcher(context)
        context.instance_exec(key, value, objects) do |k, v, o|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          object_matcher =
            o&.map { expression_matcher(_1) }&.then { match(_1) } || be_nil
          be_instance_of(Node::PklObjectEntry)
            .and have_attributes(
              key: expression_matcher(k),
              value: value_matcher, objects: object_matcher
            )
        end
      end
    end

    PklObject = Struct.new(:properties, :elements, :entries) do
      def property(name, value_or_objects)
        (self.properties ||= []) <<
          case value_or_objects
          when Array then  PklObjectProperty.new(name, nil, value_or_objects)
          else PklObjectProperty.new(name, value_or_objects, nil)
          end
      end

      def element(value)
        (self.elements ||= []) << PklObjectElement.new(value)
      end

      def entry(key, value_or_objects)
        (self.entries ||= []) <<
          case value_or_objects
          when Array then PklObjectEntry.new(key, nil, value_or_objects)
          else PklObjectEntry.new(key, value_or_objects, nil)
          end
      end

      def to_matcher(context)
        context.instance_exec(self) do |o|
          be_instance_of(Node::PklObject)
            .and have_attributes(
              properties: o.create_matcher(context, o.properties),
              elements: o.create_matcher(context, o.elements),
              entries: o.create_matcher(context, o.entries)
            )
        end
      end

      def create_matcher(context, items)
        if items.nil?
          context.__send__(:be_nil)
        else
          items
            .map { _1.to_matcher(context) }
            .then { |m| context.__send__(:match, m) }
        end
      end
    end

    def pkl_object
      o = PklObject.new
      yield(o) if block_given?
      o.to_matcher(self)
    end

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end
  end
end
