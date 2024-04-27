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

      def evaluate(context)
        push_object(context, 1) { |c| @body&.evaluate(c) }
        self
      end

      def evaluate_lazily(context)
        push_object(context, 1) { |c| @body&.evaluate_lazily(c) }
        self
      end

      def to_ruby(context)
        push_object(context, 1) { |c| create_pkl_object(c) }
          .then { _1 || PklObject::SELF }
      end

      def to_pkl_string(context)
        to_string(context)
      end

      def to_string(context)
        push_object(context, 2) { |c| to_string_object(c) }
          .then { _1 || '?' }
      end

      def copy
        self.class.new(@body&.copy, position)
      end

      def merge!(*bodies)
        return unless @body

        @body.merge!(*bodies)
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

      def push_object(context, call_limit, &block)
        return if reach_call_limit?(context, call_limit)

        super(context, self, &block)
      end

      def reach_call_limit?(context, limit)
        return false if context&.objects.nil?

        depth = call_depth(context)
        depth >= 1 && depth >= limit
      end

      def call_depth(context)
        context
          .objects
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

      def create_pkl_object(context)
        RuPkl::PklObject.new(
          to_ruby_hash(@body.properties, context),
          to_ruby_hash(@body.entries, context),
          to_ruby_array(@body.elements, context)
        )
      end

      def to_ruby_hash(members, context)
        members&.to_h { _1.to_ruby(context) }
      end

      def to_ruby_array(members, context)
        members&.map { _1.to_ruby(context) }
      end

      def to_string_object(context)
        "new #{self.class.basename} #{to_string_members(context)}"
      end

      def to_string_members(context)
        members = @body.members
        return '{}' if members.empty?

        members
          .map { _1.to_pkl_string(context) }
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
