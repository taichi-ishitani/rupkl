# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      include NodeCommon

      def initialize(body, position)
        super
        @body = body
        body && check_members
      end

      attr_reader :body

      def evaluate(scopes)
        push_scope(scopes, 1) { |s| @body.evaluate(s) }
        self
      end

      def evaluate_lazily(scopes)
        push_scope(scopes, 1) { |s| @body.evaluate_lazily(s) }
        self
      end

      def to_ruby(scopes)
        push_scope(scopes, 1) { |s| create_pkl_object(s) }
          .then { _1 || PklObject::SELF }
      end

      def to_pkl_string(scopes)
        to_string(scopes)
      end

      def to_string(scopes)
        push_scope(scopes, 2) { |s| to_string_object(s) }
          .then { _1 || '?' }
      end

      def copy
        self.class.new(@body&.copy, position)
      end

      def merge!(*bodies)
        @body&.merge!(*bodies)
        check_members
      end

      def undefined_operator?(operator)
        [:[], :==, :'!='].none?(operator)
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      private

      def check_members
        message =
          if properties_not_allowed?
            "'#{self.class.basename}' cannot have a property"
          elsif entries_not_allowed?
            "'#{self.class.basename}' cannot have an entry"
          elsif elements_not_allowed?
            "'#{self.class.basename}' cannot have an element"
          end
        message &&
          (raise EvaluationError.new(message, position))
      end

      def properties_not_allowed?
        body.properties
      end

      def entries_not_allowed?
        body.entries
      end

      def elements_not_allowed?
        body.elements
      end

      def push_scope(scopes, self_reference_limit)
        return if reach_self_reference_limit?(scopes, self_reference_limit)

        yield([*scopes, self])
      end

      def reach_self_reference_limit?(scopes, limit)
        return false if scopes.nil?

        depth = self_reference_depth(scopes)
        depth >= 1 && depth >= limit
      end

      def self_reference_depth(scopes)
        scopes
          .reverse_each
          .count { _1.equal?(self) }
      end

      def match_members?(lhs, rhs, match_order)
        if !match_order && [lhs, rhs].all?(Array)
          lhs.size == rhs.size &&
            lhs.all? { rhs.include?(_1) } && rhs.all? { lhs.include?(_1) }
        else
          lhs == rhs
        end
      end

      def create_pkl_object(scopes)
        RuPkl::PklObject.new(
          to_ruby_hash(scopes, @body.properties),
          to_ruby_hash(scopes, @body.entries),
          to_ruby_array(scopes, @body.elements)
        )
      end

      def to_ruby_hash(scopes, members)
        members
          &.to_h { _1.to_ruby(scopes) }
      end

      def to_ruby_array(scopes, members)
        members
          &.map { _1.to_ruby(scopes) }
      end

      def to_string_object(scopes)
        "new #{self.class.basename} #{to_string_members(scopes)}"
      end

      def to_string_members(scopes)
        members = @body.members
        return '{}' if members.empty?

        members
          .map { _1.to_pkl_string(scopes) }
          .join('; ')
          .then { "{ #{_1} }" }
      end

      def find_entry(key)
        entries
          &.find { _1.key == key }
          &.then(&:value)
      end

      def find_element(index)
        return nil unless elements
        return nil unless index.value.is_a?(::Integer)

        elements
          .find.with_index { |_, i| i == index.value }
          &.then(&:value)
      end
    end
  end
end
