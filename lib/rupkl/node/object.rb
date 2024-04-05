# frozen_string_literal: true

module RuPkl
  module Node
    class ObjectProperty
      def initialize(name, value, position)
        @name = name
        @value = value
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :position

      def evaluate(scopes)
        v = value.evaluate(scopes)
        self.class.new(name, v, position)
      end

      def evaluate_lazily(_scopes)
        self
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
      def initialize(key, value, position)
        @key = key
        @value = value
        @position = position
      end

      attr_reader :key
      attr_reader :value
      attr_reader :position

      def evaluate(scopes)
        k = key.evaluate(scopes)
        v = value.evaluate(scopes)
        self.class.new(k, v, position)
      end

      def evaluate_lazily(scopes)
        k = key.evaluate(scopes)
        self.class.new(k, value, position)
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
      def initialize(members, position, check_duplication: false)
        @position = position
        members&.each { add_member(_1, check_duplication) }
      end

      attr_reader :properties
      attr_reader :entries
      attr_reader :elements
      attr_reader :position

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

      def merge!(other)
        @properties = merge_properties(other)
        @entries = merge_entries(other)
        @elements = merge_elements(other)
        self
      end

      private

      def add_member(member, check_duplication)
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

      def merge_properties(other)
        merge_hash_members(properties, other.properties, :name)
      end

      def merge_entries(other)
        other_entries, _ = split_entries(other.entries)
        merge_hash_members(entries, other_entries, :key)
      end

      def merge_elements(other)
        _, other_entries = split_entries(other.entries)
        merge_array_members(elements, other.elements, other_entries, :key)
      end

      def split_entries(entries)
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
            lhs[index] = r
          else
            lhs << r
          end
        end

        lhs
      end

      def find_member_index(lhs, rhs, accessor)
        lhs.find_index { _1.__send__(accessor) == rhs.__send__(accessor) }
      end

      def merge_array_members(lhs_array, rhs_array, rhs_hash, accessor)
        return nil unless lhs_array || rhs_array
        return rhs_array unless lhs_array

        rhs_hash&.each do |r|
          index = r.__send__(accessor).value
          lhs_array[index] = r.value
        end

        lhs_array.concat(rhs_array)
      end
    end

    class UnresolvedObject
      def initialize(bodies, position)
        @bodies = bodies
        @position = position
      end

      attr_reader :bodies
      attr_reader :position

      def evaluate(scopes)
        evaluate_lazily(scopes).evaluate(scopes)
      end

      def evaluate_lazily(scopes)
        bodies = evaluate_bodies(scopes)
        Dynamic.new(bodies, position)
      end

      def to_ruby(scopes)
        evaluate(scopes).to_ruby(nil)
      end

      def to_string(scopes)
        evaluate(scopes).to_string(nil)
      end

      def to_pkl_string(scopes)
        evaluate(scopes).to_pkl_string(nil)
      end

      private

      def evaluate_bodies(scopes)
        bodies
          .map { _1.evaluate_lazily(scopes) }
          .inject { |r, b| r.merge!(b) }
      end
    end
  end
end
