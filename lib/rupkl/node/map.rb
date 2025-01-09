# frozen_string_literal: true

module RuPkl
  module Node
    class Map < Any
      MapEntry = Struct.new(:key, :value) do
        def match_key?(other_key)
          key == other_key
        end
      end

      include Operatable
      include MemberFinder
      undef_method :pkl_method

      uninstantiable_class

      def initialize(parent, entries, position)
        @entries = compose_entries(entries, position)
        super(parent, *@entries&.flat_map(&:to_a), position)
      end

      attr_reader :entries

      def evaluate(_context = nil)
        self
      end

      def to_ruby(context = nil)
        entries.to_h { |e| e.map { _1.to_ruby(context) } }
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        entry_string =
          entries
            &.flat_map { |entry| entry.map { _1.to_pkl_string(context) } }
            &.join(', ')
        "Map(#{entry_string})"
      end

      def b_op_add(r_operand, position)
        result =
          if entries && r_operand.entries
            entries + r_operand.entries
          else
            entries || r_operand.entries
          end
        self.class.new(nil, result&.flat_map(&:to_a), position)
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        return false unless entries&.size == other.entries&.size
        return true unless entries

        entries
          .all? { |entry| entry.value == other.find_by_key(entry.key) }
      end

      def find_by_key(key)
        find_entry(key)&.value
      end

      define_builtin_property(:isEmpty) do
        result = entries.nil? || entries.empty?
        Boolean.new(self, result, position)
      end

      define_builtin_property(:length) do
        result = entries&.length || 0
        Int.new(self, result, position)
      end

      define_builtin_property(:keys) do
        keys = entries&.map(&:key)
        Set.new(self, keys, position)
      end

      define_builtin_property(:values) do
        values = entries&.map(&:value)
        List.new(self, values, position)
      end

      define_builtin_property(:entries) do
        key_value_pairs =
          entries&.map { |e| Pair.new(nil, e.key, e.value, position) }
        List.new(self, key_value_pairs, position)
      end

      private

      def compose_entries(entries, position)
        return if entries.nil? || entries.empty?

        check_arity(entries, position)
        entries.each_slice(2)&.with_object([]) do |(k, v), result|
          index =
            result.find_index { _1.match_key?(k) } ||
            result.size
          result[index] = MapEntry.new(k, v)
        end
      end

      def check_arity(entries, position)
        return if ((entries&.size || 0) % 2).zero?

        m = 'number of arguments must be a multiple of two'
        raise EvaluationError.new(m, position)
      end

      def defined_operator?(operator)
        [:[], :+].any?(operator)
      end
    end
  end
end
