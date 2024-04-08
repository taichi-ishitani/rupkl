# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      include NodeCommon

      def initialize(body, position)
        super
        @body = body
      end

      attr_reader :body

      def evaluate(scopes)
        push_scope(scopes) do |s|
          self.class.new(@body.evaluate(s), position)
        end
      end

      def evaluate_lazily(scopes)
        push_scope(scopes) do |s|
          self.class.new(@body.evaluate_lazily(s), position)
        end
      end

      def to_ruby(scopes)
        push_scope(scopes) do |s|
          create_pkl_object(s)
        end
      end

      def to_pkl_string(scopes)
        push_scope(scopes) do |s|
          to_pkl_string_object(s)
        end
      end

      def to_string(scopes)
        "new #{self.class.basename} #{to_pkl_string(scopes)}"
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      private

      def push_scope(scopes)
        yield([*scopes, self])
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

      def to_pkl_string_object(scopes)
        members = @body.members
        return '{}' if members.empty?

        members
          .map { _1.to_pkl_string(scopes) }
          .join('; ')
          .then { "{ #{_1} }" }
      end
    end
  end
end
