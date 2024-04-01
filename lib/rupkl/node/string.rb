# frozen_string_literal: true

module RuPkl
  module Node
    class String
      include ValueCommon

      def initialize(value, portions, position)
        super(value, position)
        @portions = portions
      end

      attr_reader :portions

      def evaluate(_scopes)
        s = value || portions&.join || ''
        self.class.new(s, nil, position)
      end

      def to_pkl_string(scopes, **options)
        super(scopes, **options)
          .then { |s| escape(s) }
          .then { |s| "\"#{s}\"" }
      end

      def undefined_operator?(operator)
        [:[], :==, :'!='].none?(operator)
      end

      def invalid_key_operand?(key)
        !key.is_a?(Integer)
      end

      def find_by_key(key)
        index = key.value
        return nil unless (0...value.length).include?(index)

        self.class.new(value[index], nil, portions)
      end

      private

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
