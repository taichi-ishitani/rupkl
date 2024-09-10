# frozen_string_literal: true

module RuPkl
  module Node
    class Regex < Any
      uninstantiable_class

      def initialize(parent, pattern, position)
        super
        @pattern = Regexp.new(pattern.value)
      end

      attr_reader :pattern

      def evaluate(_context = nil)
        self
      end

      def to_ruby(_context = nil)
        pattern
      end

      def to_pkl_string(context = nil)
        to_string(context)
      end

      def to_string(context = nil)
        source_string = source.to_pkl_string(context)
        "Regex(#{source_string})"
      end

      def undefined_operator?(operator)
        [:==, :'!='].none?(operator)
      end

      def coerce(_operator, r_operand)
        [self, r_operand]
      end

      def ==(other)
        other.is_a?(self.class) && pattern == other.pattern
      end

      define_builtin_property(:pattern) do
        source
      end

      define_builtin_property(:groupCount) do
        Int.new(nil, group_count, position)
      end

      define_builtin_method(:findMatchesIn, input: String) do |args, parent, position|
        find_matches(args[:input].value, parent, position)
      end

      define_builtin_method(:matchEntire, input: String) do |args, parent, position|
        match_entire(args[:input].value, parent, position)
      end

      private

      def source
        @children[0]
      end

      def group_count
        Regexp::Parser
          .parse(pattern)
          .each_expression.count { |exp, _| exp.capturing? }
      end

      def find_matches(string, parent, position)
        matches = []
        offset = 0
        while (match_data = match_pattern(string, offset))
          matches << RegexMatch.create(match_data, nil, position)
          offset = calc_next_offset(match_data, offset)
        end
        List.new(parent, matches, position)
      end

      def match_entire(string, parent, position)
        match_pattern(string, 0).then do |m|
          if m && m.end(0) == string.size
            RegexMatch.create(m, parent, position)
          else
            Null.new(parent, position)
          end
        end
      end

      def match_pattern(string, offset)
        return if offset > string.size

        pattern.match(string, offset)
      end

      def calc_next_offset(match_data, offset)
        if match_data[0].empty?
          offset + 1
        else
          match_data.end(0)
        end
      end
    end

    class RegexMatch < Any
      uninstantiable_class

      class << self
        def create(match_data, parent, position)
          groups = Array.new(match_data.size) do |i|
            if match_data[i]
              create_regex_match(
                match_data[i], match_data.begin(i),
                match_data.end(i), nil, nil, position
              )
            else
              Null.new(nil, position)
            end
          end
          create_regex_match(
            match_data[0], match_data.begin(0),
            match_data.end(0), groups, parent, position
          )
        end

        private

        def create_regex_match(value, start_offset, end_offset, groups, parent, position)
          v = String.new(nil, value, nil, position)
          s = Int.new(nil, start_offset, position)
          e = Int.new(nil, end_offset, position)
          g = List.new(nil, groups, position)
          new(parent, v, s, e, g, position)
        end
      end

      def value
        @children[0]
      end

      def start
        @children[1]
      end

      def end
        @children[2]
      end

      def groups
        @children[3]
      end
    end
  end
end
