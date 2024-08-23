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
        do_evaluation(__method__, context)
      end

      def copy(parent = nil, position = @position)
        copied_members = items&.map(&:copy)
        self.class.new(parent, copied_members, position)
      end

      def current_context
        super&.push_scope(self)
      end

      def merge!(*others)
        others.each { do_merge(_1) }
        self
      end

      private

      def do_evaluation(evaluator, context)
        (context&.push_scope(self) || current_context).then do |c|
          fields.each { |f| f.__send__(evaluator, c) }
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

      protected

      def collect_members(klass)
        items
          &.select { |item| item.is_a?(klass) }
          &.then { !_1.empty? && _1 || nil }
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
