# frozen_string_literal: true

module RuPkl
  module Helpers
    def boolean_literal(value)
      be_instance_of(Node::Boolean).and have_attributes(value: value)
    end

    alias_method :be_boolean, :boolean_literal

    def integer_literal(value)
      be_instance_of(Node::Integer).and have_attributes(value: value)
    end

    alias_method :be_integer, :integer_literal

    def float_literal(value)
      be_instance_of(Node::Float).and have_attributes(value: value)
    end

    alias_method :be_float, :float_literal

    def be_number(number)
      number.is_a?(Float) && be_float(number) || be_integer(number)
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

    def evaluated_string(string)
      be_instance_of(Node::String).and have_attributes(value: string, portions: be_nil)
    end

    alias_method :be_evaluated_string, :evaluated_string

    def identifer(id)
      be_instance_of(Node::Identifier).and have_attributes(id: id.to_sym)
    end

    def member_ref(receiver_or_member, member = nil)
      receiver_matcher, memer_matcher =
        if member
          [expression_matcher(receiver_or_member), identifer(member)]
        else
          [be_nil, identifer(receiver_or_member)]
        end
      be_instance_of(Node::MemberReference)
        .and have_attributes(receiver: receiver_matcher, member: memer_matcher)
    end

    def expression_matcher(expression)
      case expression
      when TrueClass, FalseClass then boolean_literal(expression)
      when Integer then integer_literal(expression)
      when Float then float_literal(expression)
      when String then string_literal(expression).or(evaluated_string(expression))
      else expression
      end
    end

    def subscript_op(receiver, key)
      receiver_matcher = expression_matcher(receiver)
      key_matcher = expression_matcher(key)
      be_instance_of(Node::SubscriptOperation)
        .and have_attributes(operator: :[], receiver: receiver_matcher, key: key_matcher)
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

    ObjectProperty = Struct.new(:name, :value, :objects) do
      def to_matcher(context)
        context.instance_exec(name, value, objects) do |n, v, o|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          object_matcher =
            o&.map { expression_matcher(_1) }&.then { match(_1) } || be_nil
          be_instance_of(Node::ObjectProperty)
            .and have_attributes(name: identifer(n), value: value_matcher, objects: object_matcher)
        end
      end
    end

    ObjectElement = Struct.new(:value) do
      def to_matcher(context)
        context.__send__(:expression_matcher, value)
      end
    end

    ObjectEntry = Struct.new(:key, :value, :objects) do
      def to_matcher(context)
        context.instance_exec(key, value, objects) do |k, v, o|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          object_matcher =
            o&.map { expression_matcher(_1) }&.then { match(_1) } || be_nil
          be_instance_of(Node::ObjectEntry)
            .and have_attributes(
              key: expression_matcher(k),
              value: value_matcher, objects: object_matcher
            )
        end
      end
    end

    UnresolvedObject = Struct.new(:members) do
      def property(name, value_or_objects)
        (self.members ||= []) <<
          case value_or_objects
          when Array then ObjectProperty.new(name, nil, value_or_objects)
          else ObjectProperty.new(name, value_or_objects, nil)
          end
      end

      def element(value)
        (self.members ||= []) << ObjectElement.new(value)
      end

      def entry(key, value_or_objects)
        (self.members ||= []) <<
          case value_or_objects
          when Array then ObjectEntry.new(key, nil, value_or_objects)
          else ObjectEntry.new(key, value_or_objects, nil)
          end
      end

      def to_matcher(context)
        members_matcher =
          if members
            members
              .map { _1.to_matcher(context) }
              .then { _1 && context.__send__(:match, _1) }
          else
            context.__send__(:be_nil)
          end

        context.instance_exec(self) do |o|
          be_instance_of(Node::UnresolvedObject)
            .and have_attributes(members: members_matcher)
        end
      end
    end

    def unresolved_object
      o = UnresolvedObject.new
      yield(o) if block_given?
      o.to_matcher(self)
    end

    Dynamic = Struct.new(:properties, :elements, :entries) do
      def property(name, value)
        (self.properties ||= []) << ObjectProperty.new(name, value, nil)
      end

      def element(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      def entry(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value, nil)
      end

      def to_matcher(context)
        context.instance_exec(self) do |o|
          be_instance_of(Node::Dynamic)
            .and have_attributes(
              properties: o.create_matcher(context, o.properties),
              elements: o.create_matcher(context, o.elements),
              entries: o.create_matcher(context, o.entries)
            )
        end
      end

      def create_matcher(context, items)
        if items
          items
            .map { _1.to_matcher(context) }
            .then { context.__send__(:match, _1) }
        else
          context.__send__(:be_nil)
        end
      end
    end

    def dynamic
      o = Dynamic.new
      yield(o) if block_given?
      o.to_matcher(self)
    end

    alias_method :be_dynamic, :dynamic

    def match_pkl_object(properties: nil, elements: nil, entries: nil)
      properties_matcher =
        properties
          .then { _1 && match(_1) || be_empty }
      elements_matcher =
        elements
          .then { _1 && match(_1)  || be_empty }
      entries_matcher =
        entries
          .then { _1 && match(_1)  || be_empty }

      be_instance_of(RuPkl::PklObject)
        .and have_attributes(
          properties: properties_matcher,
          elements: elements_matcher,
          entries: entries_matcher
        )
    end

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end

    def raise_evaluation_error(message)
      raise_error(EvaluationError, message)
    end
  end
end
