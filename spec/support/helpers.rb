# frozen_string_literal: true

module RuPkl
  module Helpers
    def boolean_literal(value)
      be_instance_of(Node::Boolean).and have_attributes(value: value)
    end

    alias_method :be_boolean, :boolean_literal

    def int_literal(value)
      be_instance_of(Node::Int).and have_attributes(value: value)
    end

    alias_method :be_int, :int_literal

    def float_literal(value)
      be_instance_of(Node::Float).and have_attributes(value: value)
    end

    alias_method :be_float, :float_literal

    def be_number(number)
      number.is_a?(Float) && be_float(number) || be_int(number)
    end

    def string_literal(*portions)
      be_instance_of(Node::String).and have_attributes(portions: match(portions))
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
      be_instance_of(Node::String).and have_attributes(portions: match(portions_processed))
    end

    def empty_string_literal
      be_instance_of(Node::String).and have_attributes(portions: be_nil)
    end

    def evaluated_string(string)
      be_instance_of(Node::String).and have_attributes(value: string)
    end

    alias_method :be_evaluated_string, :evaluated_string

    def identifer(id)
      be_instance_of(Node::Identifier).and have_attributes(id: id.to_sym)
    end

    def this_expression
      be_instance_of(Node::This)
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
      when Integer then int_literal(expression)
      when Float then float_literal(expression)
      when String then string_literal(expression).or(evaluated_string(expression))
      when :this then this_expression
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

    class AmendExpression
      def target(expression)
        @target = expression
      end

      def body
        b = ObjectBody.new
        yield(b) if block_given?
        (@bodies ||= []) << b
      end

      def to_matcher(context)
        target_matcher =
          context.__send__(:expression_matcher, @target)
        bodies_matcher =
          @bodies
            .map { _1.to_matcher(context) }
            .then { context.__send__(:match, _1) }

        context.instance_eval do
          be_instance_of(Node::AmendExpression)
            .and have_attributes(
              target: target_matcher, bodies: bodies_matcher
            )
        end
      end
    end

    def amend_expression
      e = AmendExpression.new
      yield(e)
      e.to_matcher(self)
    end

    PklClassProperty = Struct.new(:name, :value) do
      def to_matcher(context)
        context.instance_exec(name, value) do |n, v|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          be_instance_of(Node::PklClassProperty)
            .and have_attributes(name: identifer(n), value: value_matcher)
        end
      end
    end

    ObjectProperty = Struct.new(:name, :value) do
      def to_matcher(context)
        context.instance_exec(name, value) do |n, v|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          be_instance_of(Node::ObjectProperty)
            .and have_attributes(name: identifer(n), value: value_matcher)
        end
      end
    end

    ObjectEntry = Struct.new(:key, :value) do
      def to_matcher(context)
        context.instance_exec(key, value) do |k, v|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          be_instance_of(Node::ObjectEntry)
            .and have_attributes(key: expression_matcher(k), value: value_matcher)
        end
      end
    end

    ObjectElement = Struct.new(:value) do
      def to_matcher(context)
        context.instance_exec(value) do |v|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          be_instance_of(Node::ObjectElement)
            .and have_attributes(value: value_matcher)
        end
      end
    end

    ObjectBody = Struct.new(:properties, :entries, :elements) do
      def property(name, value)
        (self.properties ||= []) << ObjectProperty.new(name, value)
      end

      def entry(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value)
      end

      def element(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      def to_matcher(context)
        properties_matcher = create_members_matcher(context, properties)
        entries_matcher = create_members_matcher(context, entries)
        elements_matcher = create_members_matcher(context, elements)

        context.instance_eval do
          be_instance_of(Node::ObjectBody)
            .and have_attributes(
              properties: properties_matcher, entries: entries_matcher,
              elements: elements_matcher
            )
        end
      end

      private

      def create_members_matcher(context, members)
        if members
          members
            .map { _1.to_matcher(context) }
            .then { context.__send__(:match, _1) }
        else
          context.__send__(:be_nil)
        end
      end
    end

    def declared_type(type)
      type_matcher =
        Array(type)
          .map { identifer(_1) }
          .then { match(_1) }
      be_instance_of(Node::DeclaredType)
        .and have_attributes(type: type_matcher)
    end

    class UnresolvedObject
      def type(t = nil)
        @type = t if t
        @type
      end

      def body
        b = ObjectBody.new
        yield(b) if block_given?
        (@bodies ||= []) << b
      end

      def to_matcher(context)
        type_matcher = @type || context.__send__(:be_nil)
        bodies_matcher =
          if @bodies
            @bodies
              .map { _1.to_matcher(context) }
              .then { context.__send__(:match, _1) }
          else
            context.__send__(:be_nil)
          end

        context.instance_eval do
          be_instance_of(Node::UnresolvedObject)
            .and have_attributes(type: type_matcher, bodies: bodies_matcher)
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
        (self.properties ||= []) << ObjectProperty.new(name, value)
      end

      def entry(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value)
      end

      def element(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      def to_matcher(context)
        context.instance_exec(self) do |o|
          be_instance_of(Node::Dynamic)
            .and have_attributes(
              properties: o.create_matcher(context, o.properties),
              entries: o.create_matcher(context, o.entries),
              elements: o.create_matcher(context, o.elements)
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

    Mapping = Struct.new(:entries) do
      def []=(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value)
      end

      def to_matcher(context)
        entries_matcher =
          if self.entries
            self
              .entries
              .map { _1.to_matcher(context) }
              .then { context.__send__(:match, _1) }
          else
            context.__send__(:be_nil)
          end
        context.instance_eval do
          be_instance_of(Node::Mapping)
            .and have_attributes(entries: entries_matcher)
        end
      end
    end

    def mapping
      m = Mapping.new
      yield(m) if block_given?
      m.to_matcher(self)
    end

    alias_method :be_mapping, :mapping

    Listing = Struct.new(:elements) do
      def <<(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      def to_matcher(context)
        elements_matcher =
          if self.elements
            self
              .elements
              .map { _1.to_matcher(context) }
              .then { context.__send__(:match, _1) }
          else
            context.__send__(:be_nil)
          end
        context.instance_eval do
          be_instance_of(Node::Listing)
            .and have_attributes(elements: elements_matcher)
        end
      end
    end

    def listing
      l = Listing.new
      yield(l) if block_given?
      l.to_matcher(self)
    end

    alias_method :be_listing, :listing

    PklModule = Struct.new(:properties) do
      def property(name, value)
        (self.properties ||= []) << ObjectProperty.new(name, value)
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

    def match_pkl_object(properties: nil, entries: nil, elements: nil)
      properties_matcher =
        properties
          .then { _1 && match(_1) || be_empty }
      entries_matcher =
        entries
          .then { _1 && match(_1)  || be_empty }
      elements_matcher =
        elements
          .then { _1 && match(_1)  || be_empty }


      be_instance_of(RuPkl::PklObject)
        .and have_attributes(
          properties: properties_matcher,
          entries: entries_matcher,
          elements: elements_matcher
        )
    end

    def to_be_empty_pkl_object
      match_pkl_object
    end

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end

    def raise_evaluation_error(message)
      raise_error(EvaluationError, message)
    end
  end
end
