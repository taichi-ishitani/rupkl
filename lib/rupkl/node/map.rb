# frozen_string_literal: true

module RuPkl
  module Node
    class Map < Any
      MapEntry = Struct.new(:key, :value) do
        def match_key?(other_key)
          key == other_key
        end
      end

      uninstantiable_class

      def initialize(parent, entries, position)
        @entries = compose_entries(entries, position)
        super(parent, *@entries&.flat_map(&:to_a), position)
      end

      attr_reader :entries

      private

      def compose_entries(entries, position)
        return if entries.empty?

        check_arity(entries, position)
        entries&.each_slice(2)&.with_object([]) do |(k, v), result|
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
    end
  end
end
