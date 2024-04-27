# frozen_string_literal: true

module RuPkl
  module Node
    class ObjectMember
      include NodeCommon

      def value
        @value_evaluated || @value
      end

      def scope
        @scope || parent
      end

      private

      def push_scope(context, &block)
        super(context, scope, &block)
      end

      def evaluate_value(evaluator, context)
        @value_evaluated = value.__send__(evaluator, context)
        @value_evaluated
      end

      def copy_value
        if @value_evaluated.respond_to?(:body)
          @value_evaluated.copy
        else
          @value.copy
        end
      end
    end

    class ObjectProperty < ObjectMember
      def initialize(scope, name, value, position)
        super(name, value, position)
        @scope = scope
        @name = name
        @value = value
      end

      attr_reader :name

      def evaluate(context)
        push_scope(context) do |c|
          evaluate_value(__method__, c)
          self
        end
      end

      def evaluate_lazily(context)
        push_scope(context) do |c|
          evaluate_value(__method__, c)
          self
        end
      end

      def to_ruby(context)
        push_scope(context) do |c|
          [name.id, evaluate_value(:evaluate, c).to_ruby(c)]
        end
      end

      def to_pkl_string(context)
        v = push_scope(context) do |c|
          evaluate_value(:evaluate, c).to_pkl_string(c)
        end

        if v.start_with?('new Dynamic')
          "#{name.id}#{v.delete_prefix('new Dynamic')}"
        else
          "#{name.id} = #{v}"
        end
      end

      def ==(other)
        name.id == other.name.id && value == other.value
      end

      def copy
        self.class.new(@scope&.copy, name, copy_value, position)
      end
    end

    class ObjectEntry < ObjectMember
      def initialize(scope, key, value, position)
        super(key, value, position)
        @scope = scope
        @key = key
        @value = value
      end

      def key
        @key_evaluated || @key
      end

      def evaluate(context)
        push_scope(context) do |c|
          evaluate_key(c)
          evaluate_value(__method__, c)
          self
        end
      end

      def evaluate_lazily(context)
        push_scope(context) do |c|
          evaluate_key(c)
          evaluate_value(__method__, c)
          self
        end
      end

      def to_ruby(context)
        k = evaluate_key(context).to_ruby(context)
        v = evaluate_value(:evaluate, context).to_ruby(context)
        [k, v]
      end

      def to_pkl_string(context)
        k = evaluate_key(context).to_pkl_string(context)
        v = evaluate_value(:evaluate, context).to_pkl_string(context)
        if v.start_with?('new Dynamic')
          "[#{k}]#{v.delete_prefix('new Dynamic')}"
        else
          "[#{k}] = #{v}"
        end
      end

      def ==(other)
        key == other.key && value == other.value
      end

      def copy
        self.class.new(@scope&.copy, key, copy_value, position)
      end

      private

      def evaluate_key(context)
        @key_evaluated ||= @key.evaluate(context.pop)
        @key_evaluated
      end
    end

    class ObjectElement < ObjectMember
      def initialize(scope, value, position)
        super(value, position)
        @scope = scope
        @value = value
      end

      def evaluate(context)
        push_scope(context) do |c|
          evaluate_value(__method__, c)
          self
        end
      end

      def evaluate_lazily(context)
        push_scope(context) do |c|
          evaluate_value(__method__, c)
          self
        end
      end

      def to_ruby(context)
        evaluate_value(:evaluate, context).to_ruby(context)
      end

      def to_pkl_string(context)
        evaluate_value(:evaluate, context).to_pkl_string(context)
      end

      def ==(other)
        value == other.value
      end

      def copy
        self.class.new(@scope&.copy, copy_value, position)
      end
    end

    class ObjectBody
      include NodeCommon

      def initialize(members, position)
        super(position)
        members&.each { add_member(_1) }
      end

      attr_reader :properties
      attr_reader :entries
      attr_reader :elements
      attr_reader :classes

      def members
        [*properties, *entries, *elements]
      end

      def evaluate(context)
        members.each { _1.evaluate(context) }
        check_duplication
        self
      end

      def evaluate_lazily(context)
        members.each { _1.evaluate_lazily(context) }
        check_duplication
        self
      end

      def merge!(*others)
        others.each { do_merge(_1) }
        self
      end

      def copy
        copied_members = members.map(&:copy)
        self.class.new(copied_members, properties)
      end

      private

      def add_member(member)
        add_child(member)
        case member
        when ObjectProperty
          (@properties ||= []) << member
        when ObjectEntry
          (@entries ||= []) << member
        when ObjectElement
          (@elements ||= []) << member
        end
      end

      def check_duplication
        check_duplication_members(@properties, :name)
        check_duplication_members(@entries, :key)
      end

      def check_duplication_members(members, accessor)
        members&.each do |member|
          duplicate_member?(members, member, accessor) &&
            (raise EvaluationError.new('duplicate definition of member', member.position))
        end
      end

      def duplicate_member?(members, member, accessor)
        count =
          members
            .count { _1.__send__(accessor) == member.__send__(accessor) }
        count > 1
      end

      def do_merge(rhs)
        rhs_entries, rhs_amend = split_entries(rhs.entries)
        @properties = merge_hash_members(@properties, rhs.properties, :name)
        @entries = merge_hash_members(@entries, rhs_entries, :key)
        @elements = merge_array_members(@elements, rhs.elements, rhs_amend, :key)
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

      def merge_hash_members(lhs, rhs, accessor)
        return nil unless lhs || rhs
        return rhs unless lhs

        rhs&.each do |r|
          if (index = find_member_index(lhs, r, accessor))
            lhs[index] = merge_hash_value(lhs[index], r)
          else
            lhs << r
          end
        end

        lhs
      end

      def merge_hash_value(lhs, rhs)
        if [lhs.value, rhs.value].all? { _1.respond_to?(:body) }
          lhs.value.merge!(rhs.value)
          lhs
        else
          rhs
        end
      end

      def find_member_index(lhs, rhs, accessor)
        lhs.find_index { _1.__send__(accessor) == rhs.__send__(accessor) }
      end

      def merge_array_members(lhs_array, rhs_array, rhs_hash, accessor)
        return nil unless lhs_array || rhs_array
        return rhs_array unless lhs_array

        rhs_hash&.each do |r|
          index = r.__send__(accessor).value
          lhs_array[index] = merge_array_value(lhs_array[index], r)
        end

        rhs_array && lhs_array.concat(rhs_array)
        lhs_array
      end

      def merge_array_value(lhs, rhs)
        if [lhs.value, rhs.value].all? { _1.respond_to?(:body) }
          lhs.value.merge!(rhs.value.body)
          lhs
        else
          lhs.class.new(rhs.scope, rhs.value, rhs.position)
        end
      end
    end

    class UnresolvedObject
      include NodeCommon

      def initialize(type, bodies, position)
        super(type, *bodies, position)
        @type = type
        @bodies = bodies
      end

      attr_reader :type
      attr_reader :bodies

      def evaluate(context)
        evaluate_lazily(context).evaluate(context)
      end

      def evaluate_lazily(context)
        (type || default_type)
          .create(bodies, position, context)
      end

      def copy
        self.class.new(type&.copy, bodies.map(&:copy), position)
      end

      private

      def default_type
        id = Identifier.new(:Dynamic, position)
        DeclaredType.new([id], position)
      end
    end
  end
end
