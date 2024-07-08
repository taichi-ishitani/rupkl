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
    end
  end
end
