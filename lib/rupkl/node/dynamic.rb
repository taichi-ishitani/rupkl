# frozen_string_literal: true

module RuPkl
  module Node
    class Dynamic
      include StructCommon

      def initialize(members, scopes, position)
        @position = position
        add_members(members, scopes)
      end

      attr_reader :properties
      attr_reader :elements
      attr_reader :entries
      attr_reader :position

      def evaluate(_scopes)
        self
      end

      def to_ruby(_scopes)
        create_pkl_object(nil, properties, elements, entries)
      end

      def merge!(other)
        @properties = merge_hash_members(properties, other.properties, :name)
        @elements = merge_array_members(elements, other.elements)
        @entries = merge_hash_members(entries, other.entries, :key)
        self
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

      def add_members(members, scopes)
        return unless members

        push_scope(scopes) do |s|
          members.each { |m| add_member(m, s) }
        end
      end

      def add_member(member, scopes)
        member.evaluate(scopes).then do |m|
          case member
          when ObjectProperty then add_property(m)
          when ObjectEntry then add_entry(m)
          else add_element(m)
          end
        end
      end

      def add_property(member)
        add_hash_member((@properties ||= []), member, :name)
      end

      def add_element(member)
        add_array_member((@elements ||= []), member)
      end

      def add_entry(member)
        add_hash_member((@entries ||= []), member, :key)
      end

      def find_element(index)
        return nil unless elements
        return nil unless index.value.is_a?(::Integer)

        elements
          .find.with_index { |_, i| i == index.value }
      end

      def find_entry(key)
        entries
          &.find { _1.key == key }
          &.then(&:value)
      end
    end
  end
end
