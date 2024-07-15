# frozen_string_literal: true

module RuPkl
  module Node
    class String < Any
      include ValueCommon

      uninstantiable_class

      def initialize(parent, value, portions, position)
        super(parent, value, position)
        @portions = portions
        portions&.each do |portion|
          portion.is_a?(NodeCommon) && add_child(portion)
        end
      end

      attr_reader :portions

      def evaluate(context = nil)
        @value ||= evaluate_portions(context)
        self
      end

      def to_pkl_string(context = nil)
        s = to_ruby(context)
        if invalid_string?(s)
          s
        else
          "\"#{escape(s)}\""
        end
      end

      def copy(parent = nil)
        copied_portions =
          portions&.map do |portion|
            portion.is_a?(NodeCommon) && portion.copy || portion
          end
        self.class.new(parent, nil, copied_portions, position)
      end

      def undefined_operator?(operator)
        [:[], :==, :'!=', :+].none?(operator)
      end

      def invalid_key_operand?(key)
        !key.is_a?(Int)
      end

      def find_by_key(key)
        index = key.value
        return nil unless (0...value.length).include?(index)

        self.class.new(parent, value[index], nil, position)
      end

      define_builtin_property(:length) do
        Int.new(self, value.length, position)
      end

      define_builtin_property(:lastIndex) do
        Int.new(self, value.length - 1, position)
      end

      define_builtin_property(:isEmpty) do
        Boolean.new(self, value.empty?, position)
      end

      define_builtin_property(:isBlank) do
        result = /\A\p{White_Space}*\z/.match?(value)
        Boolean.new(self, result, position)
      end

      define_builtin_property(:md5) do
        hash = Digest::MD5.hexdigest(value)
        String.new(self, hash, nil, position)
      end

      define_builtin_property(:sha1) do
        hash = Digest::SHA1.hexdigest(value)
        String.new(self, hash, nil, position)
      end

      define_builtin_property(:sha256) do
        hash = Digest::SHA256.hexdigest(value)
        String.new(self, hash, nil, position)
      end

      define_builtin_property(:sha256Int) do
        hash = Digest::SHA256.digest(value).unpack1('q')
        Int.new(self, hash, position)
      end

      define_builtin_property(:base64) do
        result = Base64.urlsafe_encode64(value)
        String.new(self, result, nil, position)
      end

      define_builtin_property(:base64Decoded) do
        result = Base64.urlsafe_decode64(value)
        String.new(self, result, nil, position)
      rescue ArgumentError
        message = "illegal base64: \"#{value}\""
        raise EvaluationError.new(message, position)
      end

      define_builtin_method(:getOrNull, index: Int) do |index|
        if (0...value.size).include?(index.value)
          String.new(nil, value[index.value], nil, position)
        else
          Null.new(nil, position)
        end
      end

      define_builtin_method(:substring, start: Int, exclusive_end: Int) do |s, e|
        check_range(s.value, 0)
        check_range(e.value, s.value)

        String.new(nil, value[s.value...e.value], nil, position)
      end

      define_builtin_method(:substringOrNull, start: Int, exclusive_end: Int) do |s, e|
        if inside_range?(s.value, 0) && inside_range?(e.value, s.value)
          String.new(nil, value[s.value...e.value], nil, position)
        else
          Null.new(nil, position)
        end
      end

      define_builtin_method(:repeat, count: Int) do |count|
        check_positive_number(count)

        result = value * count.value
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:contains, pattern: String) do |pattern|
        result = value.include?(pattern.value)
        Boolean.new(nil, result, position)
      end

      define_builtin_method(:startsWith, pattern: String) do |pattern|
        result = value.start_with?(pattern.value)
        Boolean.new(nil, result, position)
      end

      define_builtin_method(:endsWith, pattern: String) do |pattern|
        result = value.end_with?(pattern.value)
        Boolean.new(nil, result, position)
      end

      define_builtin_method(:indexOf, pattern: String) do |pattern|
        index_of(:index, pattern) do
          message = "\"#{pattern.value}\" does not occur in \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:indexOfOrNull, pattern: String) do |pattern|
        index_of(:index, pattern) do
          Null.new(nil, position)
        end
      end

      define_builtin_method(:lastIndexOf, pattern: String) do |pattern|
        index_of(:rindex, pattern) do
          message = "\"#{pattern.value}\" does not occur in \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:lastIndexOfOrNull, pattern: String) do |pattern|
        index_of(:rindex, pattern) do
          Null.new(nil, position)
        end
      end

      define_builtin_method(:take, n: Int) do |n|
        check_positive_number(n)

        result = value[0, n.value] || value
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:takeLast, n: Int) do |n|
        check_positive_number(n)

        pos = value.size - n.value
        result = pos.negative? && value || value[pos..]
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:drop, n: Int) do |n|
        check_positive_number(n)

        result = value[n.value..] || ''
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:dropLast, n: Int) do |n|
        check_positive_number(n)

        length = value.size - n.value
        result = length.negative? && '' || value[0, length]
        String.new(nil, result, nil, position)
      end

      define_builtin_method(
        :replaceFirst,
        pattern: String, replacement: String
      ) do |pattern, replacement|
        result = value.sub(pattern.value, replacement.value)
        String.new(nil, result, nil, position)
      end

      define_builtin_method(
        :replaceLast,
        pattern: String, replacement: String
      ) do |pattern, replacement|
        result =
          if (index = value.rindex(pattern.value))
            value.dup.tap { |s| s[index, replacement.value.size] = replacement.value }
          else
            value
          end
        String.new(nil, result, nil, position)
      end

      define_builtin_method(
        :replaceAll,
        pattern: String, replacement: String
      ) do |pattern, replacement|
        result = value.gsub(pattern.value, replacement.value)
        String.new(nil, result, nil, position)
      end

      define_builtin_method(
        :replaceRange,
        start: Int, exclusive_end: Int, replacement: String
      ) do |start, exclusive_end, replacement|
        check_range(start.value, 0)
        check_range(exclusive_end.value, start.value)

        range = start.value...exclusive_end.value
        result = value.dup.tap { |s| s[range] = replacement.value }
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:toUpperCase) do
        String.new(nil, value.upcase, nil, position)
      end

      define_builtin_method(:toLowerCase) do
        String.new(nil, value.downcase, nil, position)
      end

      define_builtin_method(:reverse) do
        String.new(nil, value.reverse, nil, position)
      end

      define_builtin_method(:trim) do
        pattern = /(?:\A\p{White_Space}+)|(?:\p{White_Space}+\z)/
        String.new(nil, value.gsub(pattern, ''), nil, position)
      end

      define_builtin_method(:trimStart) do
        pattern = /\A\p{White_Space}+/
        String.new(nil, value.sub(pattern, ''), nil, position)
      end

      define_builtin_method(:trimEnd) do
        pattern = /\p{White_Space}+\z/
        String.new(nil, value.sub(pattern, ''), nil, position)
      end

      define_builtin_method(:padStart, width: Int, char: String) do |width, char|
        pad(width, char, :pre)
      end

      define_builtin_method(:padEnd, width: Int, char: String) do |width, char|
        pad(width, char, :post)
      end

      define_builtin_method(:capitalize) do
        result =
          value.empty? && value || value.dup.tap { |s| s[0] = s[0].upcase }
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:decapitalize) do
        result =
          value.empty? && value || value.dup.tap { |s| s[0] = s[0].downcase }
        String.new(nil, result, nil, position)
      end

      define_builtin_method(:toInt) do
        to_int do
          message = "cannot parse string as Int \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toIntOrNull) do
        to_int do
          Null.new(nil, position)
        end
      end

      define_builtin_method(:toFloat) do
        to_float do
          message = "cannot parse string as Float \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toFloatOrNull) do
        to_float do
          Null.new(nil, position)
        end
      end

      define_builtin_method(:toBoolean) do
        to_boolean do
          message = "cannot parse string as Boolean \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toBooleanOrNull) do
        to_boolean do
          Null.new(nil, position)
        end
      end

      private

      def evaluate_portions(context)
        evaluated_portions =
          portions&.map do |portion|
            evaluate_portion(portion, context)
              .tap { |s| return s if invalid_string?(s) }
          end
        evaluated_portions&.join || ''
      end

      def evaluate_portion(portion, context)
        if portion.respond_to?(:to_string)
          portion.to_string(context)
        else
          portion
        end
      end

      def escape(string)
        replace = {
          "\t" => '\t', "\n" => '\n', "\r" => '\r',
          '"' => '\"', '\\' => '\\\\'
        }
        string.gsub(/([\t\n\r"\\])/) { replace[_1] }
      end

      def check_range(index, start_index)
        return if inside_range?(index, start_index)

        message = "index #{index} is out of range " \
                  "#{start_index}..#{value.size}: \"#{value}\""
        raise EvaluationError.new(message, position)
      end

      def inside_range?(index, start_index)
        (start_index..value.size).include?(index)
      end

      def index_of(method, pattern)
        result = value.__send__(method, pattern.value)
        result && Int.new(nil, result, position) || yield
      end

      def pad(width, char, pre_post)
        unless char.value.length == 1
          message = "expected a char, but got \"#{char.value}\""
          raise EvaluationError.new(message, position)
        end

        result =
          pad_prefix_postfix(width, char, pre_post)
            .then { |pre, post| [pre, value, post].join }
        String.new(nil, result, nil, position)
      end

      def pad_prefix_postfix(width, char, pre_post)
        pad_width = width.value - value.length
        if pad_width <= 0
          [nil, nil]
        elsif pre_post == :pre
          [char.value * pad_width, nil]
        else
          [nil, char.value * pad_width]
        end
      end

      def to_int
        Int.new(nil, Integer(value.gsub('_', ''), 10), position)
      rescue ArgumentError
        yield
      end

      def to_float
        result =
          case value
          when 'NaN' then ::Float::NAN
          when 'Infinity' then ::Float::INFINITY
          when '-Infinity' then -::Float::INFINITY
          else Float(value.gsub('_', ''))
          end
        Float.new(nil, result, position)
      rescue ArgumentError
        yield
      end

      def to_boolean
        result =
          case value
          when /\Atrue\z/i then true
          when /\Afalse\z/i then false
          else return yield
          end
        Boolean.new(nil, result, position)
      end
    end
  end
end
