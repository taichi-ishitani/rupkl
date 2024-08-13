# frozen_string_literal: true

module RuPkl
  module Node
    module StructCommon
      include NodeCommon
      include MemberFinder

      def initialize(parent, body, position)
        super
        @body = body
        body && check_members
      end

      attr_reader :body

      def evaluate(context = nil)
        do_evaluation(__method__, context, 1) do |c|
          @body&.evaluate(c)
        end
        self
      end

      def resolve_structure(context = nil)
        do_evaluation(__method__, context, 1) do |c|
          @body&.resolve_structure(c)
        end
        self
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        do_evaluation(__method__, context, 2, invalid_string) do |c|
          to_string_object(c)
        end
      end

      def current_context
        super&.push_object(self) || Context.new(nil, [self])
      end

      def structure?
        true
      end

      def copy(parent = nil, position = @position)
        self.class.new(parent, @body&.copy, position)
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

      def do_evaluation(method, context, limit, ifreachlimit = nil)
        return ifreachlimit if reach_limit?(method, limit)

        call_depth[method] += 1
        result = yield(context&.push_object(self) || current_context)
        call_depth.delete(method)

        result
      end

      def call_depth
        @call_depth ||= Hash.new { |h, k| h[k] = 0 }
      end

      def reach_limit?(method, limit)
        depth = call_depth[method]
        depth >= 1 && depth >= limit
      end

      def match_members?(lhs, rhs, match_order)
        if !match_order && [lhs, rhs].all?(Array)
          lhs.size == rhs.size &&
            lhs.all? { rhs.include?(_1) } && rhs.all? { lhs.include?(_1) }
        else
          lhs == rhs
        end
      end

      SELF = Object.new.freeze

      def to_pkl_object(context)
        to_ruby_object(context) do |properties, entries, elements|
          PklObject.new do |object|
            [
              replace_self_hash(properties, object),
              replace_self_hash(entries, object),
              replace_self_array(elements, object)
            ]
          end
        end
      end

      def to_ruby_object(context)
        do_evaluation(__method__, context, 1, SELF) do |c|
          results = convert_members(c)
          yield(*results)
        end
      end

      def convert_members(context)
        context.push_scope(@body).then do |c|
          to_ruby = proc { _1.to_ruby(c) }
          [
            @body.properties&.to_h(&to_ruby),
            @body.entries&.to_h(&to_ruby),
            @body.elements&.map(&to_ruby)
          ]
        end
      end

      def replace_self_hash(hash, replacement)
        hash&.each do |key, value|
          hash[key] = replacement if value.equal?(SELF)
        end
      end

      def replace_self_array(array, replacement)
        array&.each_with_index do |value, i|
          array[i] = replacement if value.equal?(SELF)
        end
      end

      def to_string_object(context)
        "new #{self.class.basename} #{to_string_members(context)}"
      end

      def to_string_members(context)
        members = @body.members
        return '{}' if members.empty?

        context.push_scope(@body).then do |c|
          members
            .map { _1.to_pkl_string(c) }
            .join('; ')
            .then { "{ #{_1} }" }
        end
      end
    end
  end
end
