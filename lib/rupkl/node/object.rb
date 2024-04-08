# frozen_string_literal: true

module RuPkl
  module Node
    class ObjectProperty
      include NodeCommon

      def initialize(name, value, position)
        super
        @name = name
        @value = value
      end

      attr_reader :name
      attr_reader :value

      def evaluate(scopes)
        v = value.evaluate(scopes)
        self.class.new(name, v, position)
      end

      def evaluate_lazily(scopes)
        if value.respond_to?(:bodies)
          v = value.evaluate_lazily(scopes)
          self.class.new(name, v, position)
        else
          self
        end
      end

      def to_ruby(scopes)
        [name.id, value.to_ruby(scopes)]
      end

      def to_pkl_string(scopes)
        v = value.to_pkl_string(scopes)
        if v.start_with?('{')
          "#{name.id} #{v}"
        else
          "#{name.id} = #{v}"
        end
      end

      def ==(other)
        name.id == other.name.id && value == other.value
      end
    end

    class ObjectEntry
      include NodeCommon

      def initialize(key, value, position)
        super
        @key = key
        @value = value
      end

      attr_reader :key
      attr_reader :value

      def evaluate(scopes)
        k = key.evaluate(scopes)
        v = value.evaluate(scopes)
        self.class.new(k, v, position)
      end

      def evaluate_lazily(scopes)
        k = key.evaluate(scopes)
        v =
          if value.respond_to?(:bodies)
            value.evaluate_lazily(scopes)
          else
            value
          end
        self.class.new(k, v, position)
      end

      def to_ruby(scopes)
        k = key.to_ruby(scopes)
        v = value.to_ruby(scopes)
        [k, v]
      end

      def to_pkl_string(scopes)
        k = key.to_pkl_string(scopes)
        v = value.to_pkl_string(scopes)
        if v.start_with?('{')
          "[#{k}] #{v}"
        else
          "[#{k}] = #{v}"
        end
      end

      def ==(other)
        key == other.key && value == other.value
      end
    end

    class ObjectBody
      include NodeCommon

      def initialize(members, position, check_duplication: false)
        super(position)
        members&.each { add_member(_1, check_duplication) }
      end

      attr_reader :properties
      attr_reader :entries
      attr_reader :elements

      def members
        [*properties, *entries, *elements]
      end

      def evaluate(scopes)
        members
          .map { _1.evaluate(scopes) }
          .then { self.class.new(_1, position, check_duplication: true) }
      end

      def evaluate_lazily(scopes)
        members
          .map { _1.evaluate_lazily(scopes) }
          .then { self.class.new(_1, position, check_duplication: true) }
      end

      def merge(*others)
        self.class.new(members, position).merge!(*others)
      end

      def merge!(*others)
        others.each { do_merge(_1) }
        self
      end

      private

      def add_member(member, check_duplication)
        add_child(member)
        case member
        when ObjectProperty
          add_hash_member((@properties ||= []), member, :name, check_duplication)
        when ObjectEntry
          add_hash_member((@entries ||= []), member, :key, check_duplication)
        else
          add_array_member((@elements ||= []), member)
        end
      end

      def add_hash_member(members, member, accessor, check_duplication)
        check_duplication && duplicate_member?(members, member, accessor) &&
          begin
            message = 'duplicate definition of member'
            raise EvaluationError.new(message, member.position)
          end
        members << member
      end

      def duplicate_member?(members, member, accessor)
        members
          .any? { _1.__send__(accessor) == member.__send__(accessor) }
      end

      def add_array_member(members, member)
        members << member
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
            .group_by do |e|
              e.key.instance_of?(Node::Integer) &&
                e.key.value < elements_size
            end
        [grouped_entries[false], grouped_entries[true]]
      end

      def merge_hash_members(lhs, rhs, accessor)
        return nil unless lhs || rhs
        return rhs unless lhs

        rhs&.each do |r|
          if (index = find_member_index(lhs, r, accessor))
            lhs[index] = merge_hash_value(lhs[index], r, accessor)
          else
            lhs << r
          end
        end

        lhs
      end

      def find_member_index(lhs, rhs, accessor)
        lhs.find_index { _1.__send__(accessor) == rhs.__send__(accessor) }
      end

      def merge_hash_value(lhs, rhs, accessor)
        new_value = merge_value(lhs.value, rhs.value)
        lhs.class.new(lhs.__send__(accessor), new_value, lhs.position)
      end

      def merge_array_members(lhs_array, rhs_array, rhs_hash, accessor)
        return nil unless lhs_array || rhs_array
        return rhs_array unless lhs_array

        rhs_hash&.each do |r|
          index = r.__send__(accessor).value
          lhs_array[index] = merge_value(lhs_array[index], r.value)
        end

        lhs_array.concat(rhs_array)
      end

      def merge_value(lhs, rhs)
        if [lhs, rhs].all? { _1.respond_to?(:body) }
          body = lhs.body.merge(rhs.body)
          lhs.class.new(body, lhs.position)
        else
          rhs
        end
      end
    end

    class UnresolvedObject
      include NodeCommon

      def initialize(bodies, position)
        super(*bodies, position)
        @bodies = bodies
      end

      attr_reader :bodies

      def evaluate(scopes)
        do_evaluate(scopes, __method__)
      end

      def evaluate_lazily(scopes)
        do_evaluate(scopes, __method__)
      end

      private

      def do_evaluate(scopes, evaluator)
        Dynamic.new(bodies.first, position)
          .__send__(evaluator, scopes)
          .tap do |o|
            bodies[1..].each do |b|
              o.body.merge!(b.__send__(evaluator, [*scopes, o]))
            end
          end
      end
    end
  end
end
