# frozen_string_literal: true

module RuPkl
  module Node
    module PropertyEvaluator
      private

      def evaluate_property(value, objects, scopes)
        value&.evaluate(scopes) || evaluate_objects(objects, scopes)
      end

      def property_to_ruby(value, objects, scopes)
        if value
          value.to_ruby(scopes)
        else
          evaluate_objects(objects, scopes).to_ruby(nil)
        end
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
          when PklObjectEntry then lhs.key.value == rhs.key.value
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
          new_members = members.map { _1.evaluate(s) }
          self.class.new(new_members, position)
        end
      end

      def to_ruby(scopes)
        push_scope(scopes) do |s|
          RuPkl::PklObject.new(
            to_ruby_hash(properties, s),
            to_ruby_array(elements, s),
            to_ruby_hash(entries, s)
          )
        end
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

      def to_ruby_hash(items, scopes)
        items&.to_h { _1.to_ruby(scopes) } || {}
      end

      def to_ruby_array(items, scopes)
        items&.map { _1.to_ruby(scopes) } || []
      end
    end
  end
end
