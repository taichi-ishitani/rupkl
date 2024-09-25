# frozen_string_literal: true

module RuPkl
  module Node
    class ObjectMember
      include NodeCommon

      def value
        @value_evaluated || @value
      end

      def add_child(child)
        super
        assign_evaluaed_value? &&
          (@value_evaluated = child)
      end

      def visibility
        @visibility || :lexical
      end

      attr_writer :visibility

      def generated?
        @generated
      end

      attr_writer :generated

      private

      def evaluate_value(evaluator, context)
        @value_evaluated = value.__send__(evaluator, context)
        value
      end
    end

    class ObjectProperty < ObjectMember
      def initialize(parent, name, value, modifiers, position)
        super(parent, name, value, position)
        @name = name
        @value = value
        @modifiers = modifiers
      end

      attr_reader :name
      attr_reader :modifiers

      def evaluate(context = nil)
        evaluate_value(__method__, context)
        self
      end

      def resolve_structure(context = nil)
        evaluate_value(__method__, context)
        self
      end

      def to_ruby(context = nil)
        [name.id, evaluate_value(:evaluate, context).to_ruby]
      end

      def to_pkl_string(context = nil)
        v = evaluate_value(:evaluate, context).to_pkl_string

        if v.start_with?('new Dynamic')
          "#{name.id}#{v.delete_prefix('new Dynamic')}"
        else
          "#{name.id} = #{v}"
        end
      end

      def ==(other)
        name == other.name && value == other.value
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, name.copy, value.copy, modifiers, position)
      end

      def local?
        @modifiers&.[](:local) || false
      end

      def coexistable?(other)
        name != other.name || local? != other.local? && !parent.equal?(other.parent)
      end

      private

      def assign_evaluaed_value?
        @name && @value
      end
    end

    class ObjectEntry < ObjectMember
      def initialize(parent, key, value, position)
        super
        @key = key
        @value = value
      end

      def key
        @key_evaluated || @key
      end

      def evaluate(context = nil)
        evaluate_key(context)
        evaluate_value(__method__, context)
        self
      end

      def resolve_structure(context = nil)
        evaluate_key(context)
        evaluate_value(__method__, context)
        self
      end

      def to_ruby(context = nil)
        k = evaluate_key(context).to_ruby
        v = evaluate_value(:evaluate, context).to_ruby
        [k, v]
      end

      def to_pkl_string(context = nil)
        k = evaluate_key(context).to_pkl_string
        v = evaluate_value(:evaluate, context).to_pkl_string
        if v.start_with?('new Dynamic')
          "[#{k}]#{v.delete_prefix('new Dynamic')}"
        else
          "[#{k}] = #{v}"
        end
      end

      def ==(other)
        key == other.key && value == other.value
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, key, value.copy, position)
      end

      def coexistable?(other)
        key != other.key
      end

      private

      def evaluate_key(context)
        @key_evaluated ||=
          (context || current_context).pop.then do |c|
            @key.evaluate(c)
          end
        @key_evaluated
      end

      def assign_evaluaed_value?
        @value && @key && @key_evaluated
      end
    end

    class ObjectElement < ObjectMember
      def initialize(parent, value, position)
        super
        @value = value
      end

      def evaluate(context = nil)
        evaluate_value(__method__, context)
        self
      end

      def resolve_structure(context = nil)
        evaluate_value(__method__, context)
        self
      end

      def to_ruby(context = nil)
        evaluate_value(:evaluate, context).to_ruby
      end

      def to_pkl_string(context = nil)
        evaluate_value(:evaluate, context).to_pkl_string
      end

      def ==(other)
        value == other.value
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, value.copy, position)
      end

      private

      def assign_evaluaed_value?
        @value
      end
    end

    class WhenGenerator
      include NodeCommon

      def initialize(parent, condition, when_body, else_body, result, position)
        super
        @condition = condition
        @when_body = when_body
        @else_body = else_body
        @result = result if result
      end

      attr_reader :condition
      attr_reader :when_body
      attr_reader :else_body

      def resolve_generator(context = nil)
        unless instance_variable_defined?(:@result)
          @result =
            if evaluate_condition(context)
              when_body.resolve_generator(context)
            else
              else_body&.resolve_generator(context)
            end
        end

        self
      end

      def copy(parent = nil, position = @position)
        if result
          self.class.new(parent, nil, nil, nil, result.copy, position)
        else
          copies = [condition, when_body, else_body].map { _1&.copy }
          self.class.new(parent, *copies, nil, position)
        end
      end

      def collect_members(klass)
        result&.collect_members(klass)
      end

      private

      attr_reader :result

      def evaluate_condition(context)
        result =
          (context || current_context.pop).then do |c|
            condition.evaluate(c)
          end
        return result.value if result.is_a?(Boolean)

        message =
          'expected type \'Boolean\', ' \
          "but got type '#{result.class_name}'"
        raise EvaluationError.new(message, position)
      end
    end

    class ForGenerator
      include NodeCommon

      def initialize(parent, key_name, value_name, iterable, body, results, position)
        super(parent, key_name, value_name, iterable, body, *results, position)
        @key_name = key_name
        @value_name = value_name
        @iterable = iterable
        @body = body
        @results = results&.map { _1.items.last }
      end

      attr_reader :key_name
      attr_reader :value_name
      attr_reader :iterable
      attr_reader :body

      def resolve_generator(context = nil)
        @results ||= iterate_body(context)
        self
      end

      def copy(parent = nil, position = @position)
        if results
          self.class.new(parent, key_name, value_name, nil, nil, copy_result, position)
        else
          copies = [iterable, body].map { _1&.copy }
          self.class.new(parent, key_name, value_name, *copies, nil, position)
        end
      end

      def collect_members(klass)
        results
          &.flat_map { collect_members_from_body(_1, klass) }
          &.compact
      end

      private

      attr_reader :results

      def copy_result
        results.map { _1.parent.copy }
      end

      ITERATION_METHODS = {
        IntSeq => :iterate_intseq,
        List => :iterate_collection,
        Set => :iterate_collection,
        Map => :iterate_map,
        Listing => :iterate_listing,
        Mapping => :iterate_mapping,
        Dynamic => :iterate_dynamic
      }.freeze

      def iterate_body(context)
        iterable_object = evaluate_iterable(context)
        if (method = ITERATION_METHODS[iterable_object.class])
          __send__(method, iterable_object)&.map do |(k, v)|
            resolve_body(k, v)
          end
        else
          message =
            "cannot iterate over value of type '#{iterable_object.class_name}'"
          raise EvaluationError.new(message, position)
        end
      end

      def evaluate_iterable(context)
        (context || current_context.pop).then do |c|
          iterable.evaluate(c)
        end
      end

      def iterate_intseq(intseq)
        intseq.to_ruby.map.with_index do |v, i|
          [Int.new(nil, i, nil), Int.new(nil, v, nil)]
        end
      end

      def iterate_collection(collection)
        collection.elements.map.with_index do |e, i|
          [Int.new(nil, i, nil), e]
        end
      end

      def iterate_map(map)
        map.entries.map do |e|
          [e.key, e.value]
        end
      end

      def iterate_listing(listing)
        listing.elements&.map&.with_index do |e, i|
          [Int.new(nil, i, nil), e.value]
        end
      end

      def iterate_mapping(mapping)
        mapping.entries&.map do |e|
          [e.key, e.value]
        end
      end

      def iterate_properties(dynamic)
        dynamic.properties&.map do |p|
          [String.new(nil, p.name.id.to_s, nil, nil), p.value]
        end
      end

      def iterate_dynamic(dynamic)
        [
          *iterate_properties(dynamic),
          *iterate_mapping(dynamic),
          *iterate_listing(dynamic)
        ]
      end

      def resolve_body(key, value)
        env = create_evaluation_env(key, value)
        body
          .copy(env)
          .tap { _1.resolve_generator(_1.current_context) }
      end

      def create_evaluation_env(key, value)
        iterators = []
        iterators << create_iterator(key_name, key) if key_name
        iterators << create_iterator(value_name, value)
        ObjectBody.new(self, iterators, position)
      end

      def create_iterator(name, value)
        ObjectProperty.new(nil, name, value, { local: true }, name.position)
      end

      def collect_members_from_body(body, klass)
        body
          .collect_members(klass)
          &.tap { |members| check_no_properties(members, klass) }
      end

      def check_no_properties(members, klass)
        return if members.empty? || klass != ObjectProperty

        message = 'cannot generate object properties'
        raise EvaluationError.new(message, position)
      end
    end

    class ObjectBody
      include NodeCommon
      include MemberFinder

      def initialize(parent, items, position)
        super(parent, *items, position)
      end

      attr_reader :pkl_classes

      alias_method :items, :children

      def properties(visibility: :lexical, all: false)
        @properties ||= collect_members(ObjectProperty)

        if all
          @properties
        elsif visibility == :lexical
          @properties&.select { _1.visibility == :lexical || _1.parent.equal?(self) }
        else
          @properties&.select { !_1.local? }
        end
      end

      def entries
        @entries ||= collect_members(ObjectEntry)
      end

      def elements
        @elements ||= collect_members(ObjectElement)
      end

      def pkl_methods
        @pkl_methods ||= collect_members(MethodDefinition)
      end

      def fields(visibility: :lexical)
        [*properties(visibility: visibility), *entries, *elements]
      end

      def definitions
        [*pkl_methods, *pkl_classes]
      end

      def members(visibility: :lexical)
        [*fields(visibility: visibility), *definitions]
      end

      def evaluate(context = nil)
        do_evaluation(__method__, context)
      end

      def resolve_structure(context = nil)
        resolve_generator(context)
        do_evaluation(__method__, context)
      end

      def copy(parent = nil, position = @position)
        copied_members = items&.map(&:copy)
        self.class.new(parent, copied_members, position)
      end

      def current_context
        super&.push_scope(self)
      end

      def resolve_generator(context = nil)
        generators&.each { _1.resolve_generator(context) }
        self
      end

      def collect_members(klass)
        items
          &.each_with_object([], &member_collector(klass))
          &.then { !_1.empty? && _1 || nil }
      end

      def merge!(*others)
        others.each { do_merge(_1) }
        self
      end

      private

      GENERATOR_CLASSES = [
        WhenGenerator,
        ForGenerator
      ].freeze

      def generator?(item)
        GENERATOR_CLASSES.any? { item.is_a?(_1) }
      end

      def generators
        items&.select { generator?(_1) }
      end

      def do_evaluation(evaluator, context)
        (context&.push_scope(self) || current_context).then do |c|
          fields&.each do |field|
            if field.generated?
              field.__send__(evaluator)
            else
              field.__send__(evaluator, c)
            end
          end
          check_duplication
          self
        end
      end

      def check_duplication
        check_duplication_members(properties(all: true))
        check_duplication_members(entries)
        check_duplication_members(pkl_methods)
      end

      def check_duplication_members(members)
        members&.each do |member|
          duplicate_member?(members, member) &&
            (raise EvaluationError.new('duplicate definition of member', member.position))
        end
      end

      def duplicate_member?(members, member)
        count = members.count { !_1.coexistable?(member) }
        count > 1
      end

      def member_collector(klass)
        proc do |item, members|
          if generator?(item)
            items = item.collect_members(klass)
            items && members.concat(items.each { _1.generated = true })
          elsif item.is_a?(klass)
            members << item
          end
        end
      end

      def do_merge(rhs)
        rhs_properties = rhs.properties(visibility: :object)
        rhs_entries, rhs_amend = split_entries(rhs.entries)
        @properties = merge_hash_members(properties(all: true), rhs_properties)
        @entries = merge_hash_members(entries, rhs_entries)
        @elements = merge_array_members(elements, rhs.elements, rhs_amend, :key)
      end

      def split_entries(entries)
        return [nil, nil] unless entries

        elements_size = elements&.size || 0
        grouped_entries =
          entries
            .group_by { index_node?(_1.key, elements_size) }
        [grouped_entries[false], grouped_entries[true]]
      end

      def index_node?(node, elements_size)
        node.instance_of?(Node::Int) && node.value < elements_size
      end

      def merge_hash_members(lhs, rhs)
        return nil unless lhs || rhs
        return rhs unless lhs

        rhs&.each do |r|
          if (index = find_member_index(lhs, r))
            lhs[index] = merge_hash_value(lhs[index], r)
          else
            r.visibility = :object
            lhs << r
          end
        end

        lhs
      end

      def merge_hash_value(lhs, rhs)
        if [lhs.value, rhs.value].all? { _1.respond_to?(:body) }
          lhs.value.merge!(rhs.value.body)
          lhs
        else
          rhs
        end
      end

      def find_member_index(lhs, rhs)
        lhs.find_index { !_1.coexistable?(rhs) }
      end

      def merge_array_members(lhs_array, rhs_array, rhs_hash, accessor)
        return nil unless lhs_array || rhs_array
        return rhs_array unless lhs_array

        rhs_hash&.each do |r|
          index = r.__send__(accessor).value
          lhs_array[index] = merge_array_value(lhs_array[index], r)
        end

        concat_array_members(lhs_array, rhs_array)
      end

      def concat_array_members(lhs_array, rhs_array)
        rhs_array
          &.each { _1.visibility = :object }
          &.then { lhs_array.concat(_1) }
        lhs_array
      end

      def merge_array_value(lhs, rhs)
        if [lhs.value, rhs.value].all? { _1.respond_to?(:body) }
          lhs.value.merge!(rhs.value.body)
          lhs
        else
          lhs.class.new(self, rhs.value, rhs.position)
        end
      end
    end

    class UnresolvedObject
      include NodeCommon

      def initialize(parent, type, bodies, position)
        super(parent, type, *bodies, position)
        @type = type
        @bodies = bodies
      end

      attr_reader :type
      attr_reader :bodies

      def evaluate(context = nil)
        resolve_structure(context).evaluate(context)
      end

      def resolve_structure(context = nil)
        exec_on(context) do |c|
          klass = find_class(c)
          create_object(klass, c)
        end
      end

      def structure?
        true
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, type, bodies, position)
      end

      private

      def find_class(context)
        type
          &.find_class(context)
          &.tap { |klass| check_class(klass) } || Dynamic
      end

      def check_class(klass)
        message =
          if klass.abstract?
            "cannot instantiate abstract class '#{klass.class_name}'"
          elsif !klass.instantiable?
            "cannot instantiate class '#{klass.class_name}'"
          else
            return
          end
        raise EvaluationError.new(message, position)
      end

      def create_object(klass, context)
        klass
          .new(parent, bodies.first.copy, position)
          .tap { _1.resolve_structure(context) }
          .tap do |o|
            bodies[1..]
              .map { _1.copy(o).resolve_structure(context) }
              .then { o.merge!(*_1) }
          end
      end
    end
  end
end
