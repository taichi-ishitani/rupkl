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

      def copy(parent = nil, position = @position)
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

      define_builtin_method(:getOrNull, index: Int) do |args, parent, position|
        index = args[:index].value
        if (0...value.size).include?(index)
          String.new(parent, value[index], nil, position)
        else
          Null.new(parent, position)
        end
      end

      define_builtin_method(
        :substring, start: Int, exclusive_end: Int
      ) do |args, parent, position|
        s = args[:start].value
        e = args[:exclusive_end].value
        check_range(s, 0, position)
        check_range(e, s, position)

        String.new(parent, value[s...e], nil, position)
      end

      define_builtin_method(
        :substringOrNull, start: Int, exclusive_end: Int
      ) do |args, parent, position|
        s = args[:start].value
        e = args[:exclusive_end].value
        if inside_range?(s, 0) && inside_range?(e, s)
          String.new(parent, value[s...e], nil, position)
        else
          Null.new(parent, position)
        end
      end

      define_builtin_method(:repeat, count: Int) do |args, parent, position|
        check_positive_number(args[:count], position)

        result = value * args[:count].value
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:contains, pattern: String) do |args, parent, position|
        result = value.include?(args[:pattern].value)
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:startsWith, pattern: String) do |args, parent, position|
        result = value.start_with?(args[:pattern].value)
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:endsWith, pattern: String) do |args, parent, position|
        result = value.end_with?(args[:pattern].value)
        Boolean.new(parent, result, position)
      end

      define_builtin_method(:indexOf, pattern: String) do |args, parent, position|
        index_of(:index, args[:pattern], parent, position) do
          message = "\"#{args[:pattern].value}\" does not occur in \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:indexOfOrNull, pattern: String) do |args, parent, position|
        index_of(:index, args[:pattern], parent, position) do
          Null.new(parent, position)
        end
      end

      define_builtin_method(:lastIndexOf, pattern: String) do |args, parent, position|
        index_of(:rindex, args[:pattern], parent, position) do
          message = "\"#{args[:pattern].value}\" does not occur in \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(
        :lastIndexOfOrNull, pattern: String
      ) do |args, parent, position|
        index_of(:rindex, args[:pattern], parent, position) do
          Null.new(parent, position)
        end
      end

      define_builtin_method(:take, n: Int) do |args, parent, position|
        check_positive_number(args[:n], position)

        result = value[0, args[:n].value] || value
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:takeLast, n: Int) do |args, parent, position|
        check_positive_number(args[:n], position)

        pos = value.size - args[:n].value
        result = pos.negative? && value || value[pos..]
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:drop, n: Int) do |args, parent, position|
        check_positive_number(args[:n], position)

        result = value[args[:n].value..] || ''
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:dropLast, n: Int) do |args, parent, position|
        check_positive_number(args[:n], position)

        length = value.size - args[:n].value
        result = length.negative? && '' || value[0, length]
        String.new(parent, result, nil, position)
      end

      define_builtin_method(
        :replaceFirst, pattern: String, replacement: String
      ) do |args, parent, position|
        result = value.sub(args[:pattern].value, args[:replacement].value)
        String.new(parent, result, nil, position)
      end

      define_builtin_method(
        :replaceLast, pattern: String, replacement: String
      ) do |args, parent, position|
        pattern = args[:pattern].value
        replacement = args[:replacement].value
        result =
          if (index = value.rindex(pattern))
            value.dup.tap { |s| s[index, replacement.size] = replacement }
          else
            value
          end
        String.new(parent, result, nil, position)
      end

      define_builtin_method(
        :replaceAll, pattern: String, replacement: String
      ) do |args, parent, position|
        result = value.gsub(args[:pattern].value, args[:replacement].value)
        String.new(parent, result, nil, position)
      end

      define_builtin_method(
        :replaceRange, start: Int, exclusive_end: Int, replacement: String
      ) do |args, parent, position|
        s = args[:start].value
        e = args[:exclusive_end].value
        r = args[:replacement].value

        check_range(s, 0, position)
        check_range(e, s, position)

        result = value.dup.tap { _1[s...e] = r }
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:toUpperCase) do |_, parent, position|
        String.new(parent, value.upcase, nil, position)
      end

      define_builtin_method(:toLowerCase) do |_, parent, position|
        String.new(parent, value.downcase, nil, position)
      end

      define_builtin_method(:reverse) do |_, parent, position|
        String.new(parent, value.reverse, nil, position)
      end

      define_builtin_method(:trim) do |_, parent, position|
        pattern = /(?:\A\p{White_Space}+)|(?:\p{White_Space}+\z)/
        String.new(parent, value.gsub(pattern, ''), nil, position)
      end

      define_builtin_method(:trimStart) do |_, parent, position|
        pattern = /\A\p{White_Space}+/
        String.new(parent, value.sub(pattern, ''), nil, position)
      end

      define_builtin_method(:trimEnd) do |_, parent, position|
        pattern = /\p{White_Space}+\z/
        String.new(parent, value.sub(pattern, ''), nil, position)
      end

      define_builtin_method(
        :padStart, width: Int, char: String
      ) do |args, parent, position|
        pad(args[:width], args[:char], :pre, parent, position)
      end

      define_builtin_method(
        :padEnd, width: Int, char: String
      ) do |args, parent, position|
        pad(args[:width], args[:char], :post, parent, position)
      end

      define_builtin_method(:capitalize) do |_, parent, position|
        result =
          value.empty? && value || value.dup.tap { |s| s[0] = s[0].upcase }
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:decapitalize) do |_, parent, position|
        result =
          value.empty? && value || value.dup.tap { |s| s[0] = s[0].downcase }
        String.new(parent, result, nil, position)
      end

      define_builtin_method(:toInt) do |_, parent, position|
        to_int(parent, position) do
          message = "cannot parse string as Int \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toIntOrNull) do |_, parent, position|
        to_int(parent, position) do
          Null.new(parent, position)
        end
      end

      define_builtin_method(:toFloat) do |_, parent, position|
        to_float(parent, position) do
          message = "cannot parse string as Float \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toFloatOrNull) do |_, parent, position|
        to_float(parent, position) do
          Null.new(parent, position)
        end
      end

      define_builtin_method(:toBoolean) do |_, parent, position|
        to_boolean(parent, position) do
          message = "cannot parse string as Boolean \"#{value}\""
          raise EvaluationError.new(message, position)
        end
      end

      define_builtin_method(:toBooleanOrNull) do |_, parent, position|
        to_boolean(parent, position) do
          Null.new(parent, position)
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

      def check_range(index, start_index, position)
        return if inside_range?(index, start_index)

        message = "index #{index} is out of range " \
                  "#{start_index}..#{value.size}: \"#{value}\""
        raise EvaluationError.new(message, position)
      end

      def inside_range?(index, start_index)
        (start_index..value.size).include?(index)
      end

      def index_of(method, pattern, parent, position)
        result = value.__send__(method, pattern.value)
        result && Int.new(parent, result, position) || yield
      end

      def pad(width, char, pre_post, parent, position)
        unless char.value.length == 1
          message = "expected a char, but got \"#{char.value}\""
          raise EvaluationError.new(message, position)
        end

        result =
          pad_prefix_postfix(width, char, pre_post)
            .then { |pre, post| [pre, value, post].join }
        String.new(parent, result, nil, position)
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

      def to_int(parent, position)
        Int.new(parent, Integer(remove_underscore_from_number(value), 10), position)
      rescue ArgumentError
        yield
      end

      def to_float(parent, position)
        result =
          case value
          when 'NaN' then ::Float::NAN
          when 'Infinity' then ::Float::INFINITY
          when '-Infinity' then -::Float::INFINITY
          else Float(remove_underscore_from_number(value))
          end
        Float.new(parent, result, position)
      rescue ArgumentError
        yield
      end

      def remove_underscore_from_number(string)
        string.gsub(/(?:(?<=\d)|(?<=.[eE][+-]))_+/, '')
      end

      def to_boolean(parent, position)
        result =
          case value
          when /\Atrue\z/i then true
          when /\Afalse\z/i then false
          else return yield
          end
        Boolean.new(parent, result, position)
      end
    end
  end
end
