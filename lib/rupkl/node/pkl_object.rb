# frozen_string_literal: true

module RuPkl
  module Node
    module PropertyEvaluator
      private

      def evaluate_property(value, objects, scopes)
        value&.evaluate(scopes) || evaluate_objects(objects, scopes)
      end

      def property_to_ruby(value, objects, scopes)
        evaluate_property(value, objects, scopes).to_ruby(nil)
      end

      def evaluate_objects(objects, scopes)
        objects
          .map { _1.evaluate(scopes) }
          .then { merge_objects(_1) }
      end

      def merge_objects(objects)
        members =
          objects
            .map(&:members)
            .inject(&method(:merge_object_members))
        PklObject.new(members, objects.first.position)
      end

      def merge_object_members(members, other_members)
        other_members.each do |member|
          if (index = members.find_index { match_member?(_1, member) })
            members[index] = member
          else
            members << member
          end
        end
        members
      end

      def match_member?(lhs, rhs)
        lhs.instance_of?(rhs.class) &&
          case lhs
          when PklObjectProperty then lhs.name.id == rhs.name.id
          when PklObjectEntry then lhs.key == rhs.key
          end
      end
    end

    class PklObjectProperty
      include PropertyEvaluator

      def initialize(name, value, objects, position)
        @name = name
        @value = value
        @objects = objects
        @position = position
      end

      attr_reader :name
      attr_reader :value
      attr_reader :objects
      attr_reader :position

      def evaluate(scopes)
        v = evaluate_property(value, objects, scopes)
        self.class.new(name, v, nil, position)
      end

      def to_ruby(scopes)
        [name.id, property_to_ruby(value, objects, scopes)]
      end

      def ==(other)
        name.id == other.name.id && value == other.value
      end
    end

    class PklObjectEntry
      include PropertyEvaluator

      def initialize(key, value, objects, position)
        @key = key
        @value = value
        @objects = objects
        @position = position
      end

      attr_reader :key
      attr_reader :value
      attr_reader :objects
      attr_reader :position

      def evaluate(scopes)
        k = key.evaluate(scopes)
        v = evaluate_property(value, objects, scopes)
        self.class.new(k, v, nil, position)
      end

      def to_ruby(scopes)
        k = key.to_ruby(scopes)
        v = property_to_ruby(value, objects, scopes)
        [k, v]
      end

      def ==(other)
        key == other.key && value == other.value
      end
    end

    class PklObject
      include StructCommon

      def initialize(members, position)
        @position = position
        members&.each do |member|
          case member
          when PklObjectProperty then add_property(member)
          when PklObjectEntry then add_entry(member)
          else add_element(member)
          end
        end
      end

      attr_reader :properties
      attr_reader :elements
      attr_reader :entries
      attr_reader :position

      def members
        [*properties, *elements, *entries]
      end

      def evaluate(scopes)
        push_scope(scopes) do |s|
          self.class.new(evaluate_members(s), position)
        end
      end

      def to_ruby(scopes)
        push_scope(scopes) do |s|
          RuPkl::PklObject.new(
            to_ruby_hash_members(properties, s, :name),
            to_ruby_array_members(elements, s),
            to_ruby_hash_members(entries, s, :key)
          )
        end
      end

      def ==(other)
        other.instance_of?(self.class) &&
          match_members?(properties, other.properties, false) &&
          match_members?(elements, other.elements, true) &&
          match_members?(entries, other.entries, false)
      end

      def undefined_operator?(operator)
        [:[], :==, :'!='].none?(operator)
      end

      def find_by_key(key)
        find_element(key) || find_entry(key)
      end

      private

      def add_property(property)
        (@properties ||= []) << property
      end

      def add_entry(entry)
        (@entries ||= []) << entry
      end

      def add_element(element)
        (@elements ||= []) << element
      end

      def evaluate_members(scopes)
        [
          *evaluate_hash_members(properties, scopes, :name),
          *evaluate_array_members(elements, scopes),
          *evaluate_hash_members(entries, scopes, :key)
        ]
      end

      def find_element(index)
        elements&.find&.with_index { |_, i| i == index.value }
      end

      def find_entry(key)
        entries
          &.find { _1.key == key }
          &.then(&:value)
      end
    end
  end
end
