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
      matcher =
        if value.nan?
          have_attributes(value: be_nan)
        else
          have_attributes(value: value)
        end
      be_instance_of(Node::Float).and matcher
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

    def null_expression
      be_instance_of(Node::Null)
    end

    alias_method :null, :null_expression

    def method_call(*args, nullable: false)
      arguments_matcher =
        if args[-1].is_a?(Array)
          args[-1]
            .map { expression_matcher(_1) }
            .then { match(_1) }
        else
          be_nil
        end
      receiver_matcher, method_name_matcher =
        if args[-1].is_a?(Array)
          [expression_matcher(args[-3]), identifer(args[-2])]
        else
          [expression_matcher(args[-2]), identifer(args[-1])]
        end
      nullable_matcher = be(nullable)

      be_instance_of(Node::MethodCall)
        .and have_attributes(
          receiver: receiver_matcher, method_name: method_name_matcher,
          arguments: arguments_matcher, nullable?: nullable_matcher
        )
    end

    def member_ref(receiver_or_member, member = nil, nullable: false)
      receiver_matcher, memer_matcher =
        if member
          [expression_matcher(receiver_or_member), identifer(member)]
        else
          [be_nil, identifer(receiver_or_member)]
        end
      nullable_matcher = be(nullable)
      be_instance_of(Node::MemberReference)
        .and have_attributes(
          receiver: receiver_matcher, member: memer_matcher,
          nullable?: nullable_matcher
        )
    end

    def list(*elements)
      elements_matcher =
        if elements.empty?
          be_nil
        else
          match(elements.map { |e| expression_matcher(e) })
        end
      be_instance_of(Node::List)
        .and have_attributes(elements: elements_matcher)
    end

    alias_method :be_list, :list

    def set(*elements)
      elements_matcher =
        if elements.empty?
          be_nil
        else
          match(elements.map { |e| expression_matcher(e) })
        end
      be_instance_of(Node::Set)
        .and have_attributes(elements: elements_matcher)
    end

    alias_method :be_set, :set

    def map(entries = nil)
      entries_matcher =
        if entries
          matchers = entries.map do |(key, value)|
            have_attributes(
              key: expression_matcher(key),
              value: expression_matcher(value)
            )
          end
          match(matchers)
        else
          be_nil
        end
      be_instance_of(Node::Map)
        .and have_attributes(entries: entries_matcher)
    end

    alias_method :be_map, :map

    def pair(first, second)
      matchers =
        [first, second].map { expression_matcher(_1) }
      be_instance_of(Node::Pair)
        .and have_attributes(first: matchers[0], second: matchers[1])
    end

    alias_method :be_pair, :pair

    def intseq(start, last, step: nil)
      start_matcher = expression_matcher(start)
      end_matcher = expression_matcher(last)
      step_matcher = expression_matcher(step) || be_nil
      be_instance_of(Node::IntSeq)
        .and have_attributes(start: start_matcher, end: end_matcher, step: step_matcher)
    end

    alias_method :be_intseq, :intseq

    def regex(pattern)
      be_instance_of(Node::Regex)
        .and have_attributes(pattern: eq(pattern))
    end

    alias_method :be_regex, :regex

    def regexp_match(value, start_index, end_index, groups = nil)
      value_matcher = expression_matcher(value)
      start_matcher = expression_matcher(start_index)
      end_matcher = expression_matcher(end_index)
      groups_matcher = list(*groups)
      be_instance_of(Node::RegexMatch)
        .and have_attributes(
          value: value_matcher, start: start_matcher,
          end: end_matcher, groups: groups_matcher
        )
    end

    alias_method :be_regxp_match, :regexp_match

    def expression_matcher(expression)
      case expression
      when NilClass then be_nil
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

    def non_null_op(operand)
      be_instance_of(Node::NonNullOperation)
        .and have_attributes(operand: expression_matcher(operand))
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

    def null_coalescing_op(l_operand, r_operand)
      l_matcher = expression_matcher(l_operand)
      r_matcher = expression_matcher(r_operand)
      be_instance_of(Node::NullCoalescingOperation)
        .and have_attributes(l_operand: l_matcher, r_operand: r_matcher)
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

    class IfExpression
      def condition(expression)
        @condition = expression
      end

      def if_expression(expression)
        @if_expression = expression
      end

      def else_expression(expression)
        @else_expression = expression
      end

      def to_matcher(context)
        context.instance_exec([@condition, @if_expression, @else_expression]) do |args|
          matchers = args.map { expression_matcher(_1) }
          be_instance_of(Node::IfExpression)
            .and have_attributes(
              condition: matchers[0], if_expression: matchers[1], else_expression: matchers[2]
            )
        end
      end
    end

    def if_expression
      e = IfExpression.new
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

    ObjectProperty = Struct.new(:name, :value, :modifiers) do
      def to_matcher(context)
        context.instance_exec(name, value, modifiers) do |n, v, m|
          value_matcher =
            (v || v == false) && expression_matcher(v) || be_nil
          modifiers_matcher =
            m.empty? && be_nil || match(m)
          be_instance_of(Node::ObjectProperty)
            .and have_attributes(
              name: identifer(n), value: value_matcher, modifiers: modifiers_matcher
            )
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

    class MethodParam
      def initialize(name, type)
        @name = name
        @type = type
      end

      def to_matcher(context)
        context.instance_exec(@name, @type) do |name, type|
          type_matcher = type || be_nil
          be_instance_of(Node::MethodParam)
            .and have_attributes(name: identifer(name), type: type_matcher)
        end
      end
    end

    def param(name, type = nil)
      MethodParam.new(name, type)
    end

    class MethodDefinition
      def initialize(name, params: nil, type: nil, body: nil)
        @name = name
        @params = params
        @type = type
        @body = body
      end

      def to_matcher(context)
        context.instance_exec(@name, @params, @type, @body) do |name, params, type, body|
          params_matcher =
            if params
              match(params.map { _1.to_matcher(self) })
            else
              be_nil
            end
          type_matcher = type || be_nil
          be_instance_of(Node::MethodDefinition)
            .and have_attributes(
              name: identifer(name), params: params_matcher,
              type: type_matcher, body: expression_matcher(body)
            )
        end
      end
    end

    ObjectBody = Struct.new(:items) do
      def property(name, value, **modifiers)
        (self.items ||= []) << ObjectProperty.new(name, value, modifiers)
      end

      def entry(key, value)
        (self.items ||= []) << ObjectEntry.new(key, value)
      end

      def element(value)
        (self.items ||= []) << ObjectElement.new(value)
      end

      def method(name, **kwargs)
        (self.items ||= []) << MethodDefinition.new(name, **kwargs)
      end

      def when_generator
        (self.items ||= []) << WhenGenerator.new
        yield(self.items.last)
      end

      def for_generator(*args, &body)
        (self.items ||= []) << ForGenerator.new(*args, &body)
      end

      def to_matcher(context)
        context.instance_exec(items) do |items|
          items_matcher =
            items
              &.map { _1.to_matcher(self) }
              .then { _1 && match(_1) || be_nil }
          be_instance_of(Node::ObjectBody)
            .and have_attributes(items: items_matcher)
        end
      end
    end

    class WhenGenerator
      def condition(expression = nil)
        @condition = expression if expression
        @condition
      end

      def when_body
        if block_given?
          body = ObjectBody.new
          yield(body)
          @when_body = body
        end
        @when_body
      end

      def else_body
        if block_given?
          body = ObjectBody.new
          yield(body)
          @else_body = body
        end
        @else_body
      end

      def to_matcher(context)
        context.instance_exec(self) do |generator|
          condition_matcher = expression_matcher(generator.condition)
          when_body_matcher = generator.when_body.to_matcher(self)
          else_body_matcher = generator.else_body&.to_matcher(self) || be_nil

          be_instance_of(Node::WhenGenerator)
            .and have_attributes(
              condition: condition_matcher, when_body: when_body_matcher,
              else_body: else_body_matcher
            )
        end
      end
    end

    class ForGenerator
      def initialize(*args)
        @key_name, @value_name, @iterable =
          if args.size == 3
            args
          else
            [nil, *args]
          end
        @body = ObjectBody.new
        yield(@body)
      end

      attr_reader :key_name
      attr_reader :value_name
      attr_reader :iterable
      attr_reader :body

      def to_matcher(context)
        context.instance_exec(self) do |generator|
          key_matcher = generator.key_name && identifer(generator.key_name) || be_nil
          value_matcher = identifer(generator.value_name)
          iterable_matcher = expression_matcher(generator.iterable)
          body_matcher = generator.body.to_matcher(self)

          be_instance_of(Node::ForGenerator)
            .and have_attributes(
              key_name: key_matcher, value_name: value_matcher,
              #iterable: iterable_matcher, body: body_matcher
            )
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
      def property(name, value, **modifiers)
        (self.properties ||= []) << ObjectProperty.new(name, value, modifiers)
      end

      def entry(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value)
      end

      alias_method :[], :entry

      def element(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      alias_method :<<, :element

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

    Mapping = Struct.new(:properties, :entries) do
      def []=(key, value)
        (self.entries ||= []) << ObjectEntry.new(key, value)
      end

      def to_matcher(context)
        properties_matcher = context.instance_eval { be_nil.or be_empty }
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
            .and have_attributes(
              properties: properties_matcher, entries: entries_matcher
            )
        end
      end
    end

    def mapping
      m = Mapping.new
      yield(m) if block_given?
      m.to_matcher(self)
    end

    alias_method :be_mapping, :mapping

    Listing = Struct.new(:properties, :elements) do
      def <<(value)
        (self.elements ||= []) << ObjectElement.new(value)
      end

      def to_matcher(context)
        properties_matcher = context.instance_eval { be_nil.or be_empty }
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
            .and have_attributes(
              properties: properties_matcher, elements: elements_matcher
            )
        end
      end
    end

    def listing
      l = Listing.new
      yield(l) if block_given?
      l.to_matcher(self)
    end

    alias_method :be_listing, :listing

    class PklModule
      def initialize(evaluated)
        @evaluated = evaluated
      end

      def property(name, value, **modifiers)
        (evaluated? ? (@properties ||= []) : (@items ||= [])) <<
          ObjectProperty.new(name, value, modifiers)
      end

      def method(name, **kwargs)
        (evaluated? ? (@methods ||= []) : (@items ||= [])) <<
          MethodDefinition.new(name, **kwargs)
      end

      def to_matcher(context)
        members =
          if evaluated?
            { properties: @properties, pkl_methods: @methods }
          else
            { items: @items }
          end
        context.instance_exec(members) do |members|
          matcher = members.transform_values do |member|
            member
              &.map { _1.to_matcher(self) }
              .then { _1 && match(_1) || be_nil }
          end

          be_instance_of(Node::PklModule)
            .and have_attributes(matcher)
        end
      end

      private

      def evaluated?
        @evaluated
      end
    end

    def pkl_module(evaluated: true)
      m = PklModule.new(evaluated)
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

    def match_array(*elements)
      elements_matcher =
        if elements.empty?
          be_empty
        else
          match(elements)
        end
      be_instance_of(Array).and elements_matcher
    end

    def match_hash(hash = nil)
      hash_matcher = hash && match(hash) || be_empty
      be_instance_of(Hash).and hash_matcher
    end

    def raise_parse_error(message)
      raise_error(ParseError, message)
    end

    def raise_evaluation_error(message)
      raise_error(EvaluationError, message)
    end
  end
end
